package Aion::Aya::Appearance;
# Среда исполнения / менеджер сущностей / Пульт управления
# Реализует паттерны Identity Map и Facade

use common::sense;

use Scalar::Util qw//;

use constant FS => "\f";


use Aion;

use Aion::Env::Etc ADAPTERS => (isa => Any, default => [], key => 'aion.aya.adapters');

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

1;
