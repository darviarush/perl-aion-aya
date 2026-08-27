package Aion::Aya::Appearance;
# Среда исполнения / менеджер сущностей / Пульт управления
# Реализует паттерны Identity Map и Facade

use common::sense;

use Scalar::Util qw//;
use aliased 'Aion::Aya::Adapter';
use aliased 'Aion::Aya::Model';
use aliased 'Aion::Aya::QueryBuilder';

use Aion;

use Aion::Env::Etc ADAPTER => (
	isa => HashRef[
		Dict[
			adapter => Str,
			dsn => Str,
			login => Option[Str], 
			password => Option[Str],
			attr => Option[HashRef],
		]
	],
	default => {},
	key => 'aion.aya.adapter'
);

use constant ERROR_FETCH_PKEY => "No primary key";
use constant FS => "\f";

# Адаптер для доступа к базе
has adapter => (is => 'ro', isa => Adapter, default => sub {
	my ($self) = @_;
	my $config = ADAPTER->{default} or die "aion.aya.adapter.default does not exist!";
	my %config = %$config;
	my $adapter_class = delete $config{adapter};
	eval "require $adapter_class" or die;
	$adapter_class->new(%config);
});

# Область отслеживания объектов / Identity Map (Карта идентичности)
has _area => (is => 'ro-', isa => HashRef['Aion::Aya'], lazy => 0, default => sub {+{}});

# Копии объектов сделанные при attach или предыдущем flush. Если копии нет, то объект идёт на удаление
has _copy => (is => 'ro-', isa => HashRef['Aion::Aya'], lazy => 0, default => sub {+{}});

# Добавляет объекты в область слежения
sub persist {
	my $self = shift;
	
	for my $object (@_) {
		my $key = $self->get_pkey($object);
		unless(defined $key) {
			my $model = Model->get($object);
			$model->next->
		}
		next if exists $self->{_area}{$key};
			next;
		}

		$self->{_area}{$key} = $object;
		Scalar::Util::weaken $self->{_area}{$key};

		# Ссылки в копии не задерживаются
		my %copy = %$object;
		while(my ($field, $val) = each %copy) {
			Scalar::Util::weaken $copy{$field} if ref $val;
		}
		$self->{_copy}{$key} = \%copy;
		
		$object->_appearance($self);
	}
	
	$self
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

	my $query = QueryBuilder->new(_appearance => $self, _from => ref $object);

	my $model = Model->get($object);
	my $pk_fields = $model->primary_key->{fields};
	$query = $query->filter(map {($_ => $object->{$_})} @$pk_fields);

	# fetch_key
	my $fk_fields = $model->fetch_key->{$field}{fields};
	if(defined $fetch_key) {
		my @fk_fields = grep { !exists $object{$_} } @$fk_fields;
		return $self unless @fk_fields;
		my $obj = $query->annotate(@fk_fields)->first;
		for my $fk_field (@fk_fields) {
			$object->{$fk_field} = $obj{$fk_field};
		}
	}
	else {
		$self->{$field} = $query->scalar($field);
	}

	$self
}

# Возвращает ключ объекта в виде строки
sub get_pkey {
	my ($self, $object) = @_;

	my $model = Model->get($object);
	my $pk = $model->primary_key or die sprintf "%s is'nt primary key", ref $object;
	join FS, map $object->{$_}, @{$pk->{fields}};
}

# Сохраняет объекты в базу
sub flush {
	my ($self) = @_;
	
	...
}

# Объявляет транзакцию
sub transaction {
	my ($self) = @_;
	
	Transaction->new();
}

1;
