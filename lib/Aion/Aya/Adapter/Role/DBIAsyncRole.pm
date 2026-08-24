package Aion::Aya::Adapter::Role::DBAsyncRole;

use common::sense;

use Aion -role;

# Порождает итератор
sub iterator :Isa(Me => Object[Iterator]) {
	my ($self) = @_;

	Iterator->new(adapter => $self, session => 0);
}

# Следующее значение из сессии
sub next :Isa(Me => Any => Any) {
	my ($self, $session) = @_;
	
	$self
}

1;