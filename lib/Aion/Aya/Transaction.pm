package Aion::Aya::Transaction;

use common::sense;

use Coro qw//;

use Aion;

# В каком волокне транзакция
has coro => (is => 'ro', isa => 'Coro::State', default => sub {
	$Coro::current;
});

# 
sub commit {
	my ($self) = @_;
	
	$self
}

# 
sub rollback {
	my ($self) = @_;
	
	$self
}

1;