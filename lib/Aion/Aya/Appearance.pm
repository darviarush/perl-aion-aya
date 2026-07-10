package Aion::Aya::Appearance;
# Среда исполнения / менеджер сущностей / Пульт управления
# Реализует паттерны Identity Map и Facade

use common::sense;

use Scalar::Util qw//;

use constant FS => "\f";

use Aion;

# 
#has connect => (is => 'ro', isa => );

# Область отслеживания объектов / Identity Map (Карта идентичности)
has area => (is => 'ro-', isa => HashRef['Aion::Aya'], lazy => 0, default => sub {+{}});

# Добавляет объекты в область слежения
sub persist {
	my $self = shift;
	
	for my $object (@_) {
		my $key = $self->get_pkey($object);
		$self->{area}{$key} = $object;
		Scalar::Util::weaken $self->{area}{$key};
		$object->_appearance($self);
	}
	
	$self
}

# Отключает объекты от области слежения
sub detach {
	my $self = shift;

	for my $object (@_) {
		delete $self->{area}{$self->get_pkey($object)};
		$object->_appearance(undef);
	}
	
	$self
}

# Получить поле объекта из кеша или базы. 
sub fetch {
	my ($self, $field) = @_;

	my $feature = $Aion::META{ref $self}{feature}{$field};

	$self->{$name} = ...;
}

# Возвращает ключ для записи
sub get_pkey {
	my ($self, $object) = @_;
	
	my $pk = $Aion::Aya::META{ref $object}{primary_key} or die sprintf "%s is'nt primary key", ref $object;
	join FS, map $object->{$_}, @{$pk->{fields}};
}

# Сохраняет объекты в базу
sub flush {
	my ($self) = @_;
	
	$self
}

# Сохранение в базу
sub save {
	my ($self, $pool) = @_;

	$pool //= $Aion::Model::Connects::connects;

	my $connect = $pool->get;
	my $guard = Guard::guard { $pool->put($connect) };

	my $pkg = ref $self;
	my $meta = $Aion::META{$pkg};
	my $table = $meta->{table};
	my $features = $meta->{feature};
	my $pkfields = $meta->{primary_key}{fields};
	my $pk = $pkfields->[0];

	# Если есть pk – update, иначе – insert и установка pk

	if ($self->has($pk)) {
		my @set;
		for my $feature (sort { $a->{order} <=> $b->{order} } values %$features) {
			if($feature->{col} and $self->has($feature->{name})) {
				my $name = $feature->{name};
				my $value = $self->$name;
				push @set, sprintf "%s = %s", $connect->word($feature->{col}), $connect->quote($value, $feature->{isa});
			}
		}

		my $where = join " AND ", map {
			my $feature = $features->{$_};
			sprintf "%s = %s", $connect->word($feature->{col}), $connect->quote($value, $feature->{isa})
		} @$pkfields;

		$connect->do("UPDATE ${\$connect->word($table)} SET ${\join ', ', @set} WHERE $where");
	} else {
    	my @fields;
    	my @values;
    	for my $feature (sort { $a->{order} <=> $b->{order} } values %$features) {
    		if($feature->{col} and $self->has($feature->{name})) {
    			my $name = $feature->{name};
    			my $value = $self->$name;
                push @fields, $connect->word($feature->{col});
                push @values, $connect->quote($value, $feature->{isa});
    		}
    	}

		$connect->do("INSERT INTO ${$connect->word($table)\} (${\join ', ', @fields}) VALUES (${\join ', ', @values})");

		if(0 == @$pkfields && $features->{$pk}{auto_increment}) {
			$self->{$pk} = $connect->do("LAST_INSERT_ID()");
		}
	}
}

1;
