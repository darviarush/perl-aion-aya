package Aion::Aya::Appearance;
# Среда исполнения / менеджер сущностей / Пульт управления
# Реализует паттерны Identity Map и Facade

use common::sense;

use Scalar::Util qw//;
use aliased 'Aion::Aya::Adapter';
use aliased 'Aion::Aya::Model';
use aliased 'Aion::Aya::QueryBuilder';
use aliased 'Aion::Aya::Transaction';
use aliased 'Aion::Aya::Query::Expr::Val';
use aliased 'Aion::Aya::Event::PreFlush';
use aliased 'Aion::Aya::Event::OnFlush';
use aliased 'Aion::Aya::Event::PostFlush';
use aliased 'Aion::Aya::Event::PrePersist';
use aliased 'Aion::Aya::Event::PostPersist';
use aliased 'Aion::Aya::Event::PreUpdate';
use aliased 'Aion::Aya::Event::PostUpdate';
use aliased 'Aion::Aya::Event::PreRemove';
use aliased 'Aion::Aya::Event::PostRemove';

use Aion;

use constant ERROR_FETCH_PKEY => "No primary key";
use constant FS => "\f";

# Адаптер для доступа к базе
has _adapter => (is => 'ro', isa => Adapter, eon => 1);

# Кеш
has _cache => (is => 'ro', isa => 'CHI', eon => 1);

# Эмиттер
has _emitter => (is => 'ro', isa => Object['Aion::Emitter'], eon => 1);

# Область отслеживания объектов / Identity Map (Карта идентичности)
has _area => (is => 'ro-', isa => HashRef['Aion::Aya'], lazy => 0, default => sub {+{}});

# Копии объектов сделанные при attach или предыдущем flush. Если копии нет, то объект идёт на удаление
has _copy => (is => 'ro-', isa => HashRef['Aion::Aya'], lazy => 0, default => sub {+{}});

# Добавляет объекты в область слежения
sub persist {
	my $self = shift;
	
	for my $object (@_) {
		my $key = $self->get_pkey($object);
		if(!length $key) {                 # нового объекта ещё нет — выдаём ему первичный ключ
			$self->_set_id($object);
			$key = $self->get_pkey($object);
		}
		next if exists $self->{_area}{$key};

		$self->{_area}{$key} = $object;
		Scalar::Util::weaken $self->{_area}{$key};
		$self->{_copy}{$key} = $self->_snapshot($object);
		
		$object->_appearance($self);
	}
	
	$self
}

# Выдаёт новому объекту первичный ключ из генератора next: константа (-identity, -auto_increment)
# дёргает next_val($object) у адаптера, а функция — вызывается сама
sub _set_id {
	my ($self, $object) = @_;

	my $model = Model->get($object);
	my $pk = $model->primary_key->{fields};
	die "Many pk fields on ".ref($object) unless @$pk == 1;

	my $gen = $model->next;
	$object->{$pk->[0]} = ref $gen eq 'CODE'? $gen->($object): $self->_adapter->next_val($object);
}

# Отключает объекты от области слежения
sub detach {
	my $self = shift;

	for my $object (@_) {
		my $key = $self->get_pkey($object) // die ERROR_FETCH_PKEY;
		delete $self->{_area}{$key};
		delete $self->{_copy}{$key};
		$object->_appearance(undef);
	}
	
	$self
}

# Обновляет объекты. Удаляет из копии все поля, кроме полей относящихся к PRIMARY KEY
sub refresh {
my $self = shift;

	for my $object (@_) {
		my $key = $self->get_pkey($object) // die ERROR_FETCH_PKEY;
		my $fields = Model->get($object)->primary_key->{fields};
		my $copy = $self->{_copy}{$key};
		delete $copy->{$_} for grep { !($_ ~~ $fields) } keys %$copy;
	}

	$self
}

# Помещает объекты в очередь на удаление
sub remove {
	my ($self) = @_;
	
	for my $object (@_) {
		my $key = $self->get_pkey($object) // die ERROR_FETCH_PKEY;
		delete $self->{_copy}{$key};
	}

	$self
}

# Получить поле объекта из кеша или базы
sub fetch {
	my ($self, $object, $field) = @_;

	my $model = Model->get($object);

	# Поле входит в memory_key: достаём всю строку этого ключа из кеша
	if ($self->_cache && (my $memory_key = $model->memory_key->{$field})) {
		my $cache_key = $self->_cache_key($memory_key, $model, $object);

		# Если ключа ещё нет в кеше — подгружаем поля ключа из базы и кладём туда
		my $value = $self->_cache->compute($cache_key, undef, sub {
			my $obj = $self->_fetch($object, @{$memory_key->{fields}});
			+{ map { $_ => $obj->{$_} } @{$memory_key->{fields}} };
		});

		# Заполняем объект полями ключа, которых в нём ещё нет
		for my $mfield (@{$memory_key->{fields}}) {
			$object->{$mfield} = $value->{$mfield} unless exists $object->{$mfield};
		}

		return $self;
	}

	# fetch_key: подгружаем из базы поля ключа (или одно поле, если ключа нет)
	my $fk_fields = $model->fetch_key->{$field}{fields};
	$fk_fields = [$field] unless defined $fk_fields;
	my @fk_fields = grep { !exists $object->{$_} } @$fk_fields;
	return $self unless @fk_fields;
	my $obj = $self->_fetch($object, @fk_fields);
	for my $fk_field (@fk_fields) {
		$object->{$fk_field} = $obj->{$fk_field};
	}

	$self
}

# Подгружает из базы объект со всеми указанными @fields по первичному ключу
sub _fetch {
	my ($self, $object, @fields) = @_;

	my $model = Model->get($object);
	my $query = QueryBuilder->new(_appearance => $self, _from => ref $object);
	$query = $query->filter(map {($_ => $object->{$_})} @{$model->primary_key->{fields}});
	$query->annotate(@fields)->first // die "Not object by pk!";
}

# Формирует ключ кеша по формату name из memory_key:
# {*} — имя таблицы, {field} — значение поля объекта; экранированное \{field} остаётся как есть
sub _cache_key {
	my ($self, $key, $model, $object) = @_;

	my $name = $key->{name};
	$name =~ s/\\\{/\x00/g;
	$name =~ s/\{([^}]*)\}/ $1 eq '*'? $model->table: $object->{$1} /ge;
	$name =~ s/\x00/\{/g;
	$name
}

# Возвращает ключ объекта в виде строки
sub get_pkey {
	my ($self, $object) = @_;

	my $model = Model->get($object);
	my $pk = $model->primary_key or die sprintf "%s is'nt primary key", ref $object;
	join FS, map {$object->{$_}} @{$pk->{fields}};
}

# Сохраняет объекты в базу
sub flush {
	my ($self) = @_;

	$self->_emit_flush(PreFlush);

	# Разделяем объекты: у кого есть копия — сохраняем (insert/update), у кого нет — удаляем
	my (@deletes, @saves);
	for my $key (keys %{$self->{_area}}) {
		my $object = $self->{_area}{$key} or next; # слабая ссылка могла уже отвалиться
		push @{$self->{_copy}{$key}? \@saves: \@deletes}, $object;
	}

	$self->_emit_flush(OnFlush);

	# Сначала сохраняем (родители раньше детей, чтобы FK указывали на существующие записи),
	# затем удаляем (дети раньше родителей)
	$self->_save($_)   for $self->_ordered(@saves);
	$self->_delete($_) for reverse $self->_ordered(@deletes);

	$self->_emit_flush(PostFlush);

	# Переснимаем копии для следующего flush
	for my $key (keys %{$self->{_area}}) {
		my $object = $self->{_area}{$key} or next;
		$self->{_copy}{$key} = $self->_snapshot($object);
	}

	$self
}

# Создаёт снимок объекта для _copy: ослабленные ссылки на поля
sub _snapshot {
	my ($self, $object) = @_;

	my %copy = %$object;
	Scalar::Util::weaken $copy{$_} for grep { ref $copy{$_} } keys %copy;
	\%copy;
}

# Сохраняет объект: INSERT (если нет первичного ключа) или UPDATE изменённых полей
sub _save {
	my ($self, $object) = @_;

	my $model = Model->get($object);
	my $pk = $model->primary_key->{fields};
	my $pkey = $self->get_pkey($object);          # пустое — нового объекта ещё нет в базе
	my $qb = QueryBuilder->new(_appearance => $self, _from => ref $object);

	my @data;
	my $copy = exists $self->{_copy}->{$pkey}? $self->{_copy}->{$pkey}: {};
	for my $field (keys %$object) {
		next if ref $object->{$field};            # ссылки на сущности не колонки
		next if $pkey && exists $copy->{$field} && $self->_same($copy->{$field}, $object->{$field});
		push @data, Val->new(value => $object->{$field}) => $field;
	}
	return if $pkey && !@data;                    # обновлять нечего

	if ($pkey) {                                  # UPDATE: только изменённые поля, по первичному ключу
		$self->_emit_entity(PreUpdate, $object);
		$qb = $qb->update(@data)->filter(map {($_ => $object->{$_})} @$pk);
		$qb->execute;
		$self->_emit_entity(PostUpdate, $object);
	} else {                                      # INSERT: все поля
		$self->_emit_entity(PrePersist, $object);
		$qb = $qb->insert(@data);
		$qb->execute;
		$self->_emit_entity(PostPersist, $object);
	}
}

# Удаляет объект из базы по первичному ключу
sub _delete {
	my ($self, $object) = @_;

	my $model = Model->get($object);
	my $pk = $model->primary_key->{fields};
	my $qb = QueryBuilder->new(_appearance => $self, _from => ref $object);
	$qb = $qb->delete->filter(map {($_ => $object->{$_})} @$pk);
	$self->_emit_entity(PreRemove, $object);
	$self->_adapter->execute($qb->{_query});
	$self->_emit_entity(PostRemove, $object);
}

# Собирает объекты в порядке сохранения: объекты, на которые ссылаются (FK), сохраняются раньше
sub _ordered {
	my ($self, @objects) = @_;

	my %seen;
	my @out;
	my $visit;
	$visit = sub {
		my ($value) = @_;

		if (Scalar::Util::blessed $value) {
			my $id = ref($value) . FS . $value;
			return if $seen{$id}++;
			$visit->($_) for grep { ref $_ } values %$value;
			push @out, $value;
		}
		elsif (ref $value eq 'ARRAY') {
			$visit->($_) for @$value;
		}
	};

	$visit->($_) for @objects;
	@out
}

# Одинаковые ли значения
sub _same {
	my ($a, $b) = @_;
	return 1 if !defined $a && !defined $b;
	return 0 if !defined $a || !defined $b;
	$a eq $b;
}

# Рассылает flush-событие
sub _emit_flush {
	my ($self, $class) = @_;
	$self->_emitter->emit($class->new(adapter => $self));
}

# Рассылает событие конкретной сущности
sub _emit_entity {
	my ($self, $class, $object) = @_;
	$self->_emitter->emit($class->new(adapter => $self, entity => $object));
}

# Объявляет транзакцию: 
#
#   my $transaction = $appearance->transaction;
#   ...
#   $transaction->commit;
#
# Если переменная уйдёт из области видимости без commit, то сработает rollback
sub transaction {
	my ($self) = @_;
	
	Transaction->new();
}

1;
