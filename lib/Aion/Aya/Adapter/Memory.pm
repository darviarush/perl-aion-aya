package Aion::Aya::Adapter::Memory;

use common::sense;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Iterator';

use Aion;

with 'Aion::Aya::Adapter';


# Трансформирует запрос в промежуточное представление
sub transform :Isa(Me => Query => (ArrayRef|HashRef|Str)) {
	my ($self, $query) = @_;
	
	$self
}

# Порождает итератор
sub iterator {
	my ($self) = @_;
	
	Iterator->new(adapter => $self, session => );
}

# Следующее значение из сессии
sub next {
	my ($self, $session) = @_;
	
	$self
}

1;