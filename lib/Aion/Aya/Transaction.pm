package Aion::Aya::Transaction;

use common::sense;

use Coro qw//;

use aliased 'Aion::Aya::Adapter';

use Aion;

# Адаптер
has adapter => (is => 'ro+', isa => Adapter, trigger => sub { my ($self) = @_; $self->adapter->begin_transaction($self) });

# В каком волокне транзакция
has coro_current_addr => (is => 'ro-', isa => Str, lazy => 0, default => sub { pack 'J', Scalar::Util::refaddr $Coro::current });

# Коннекты к базе, которые нужно закомитить или откатить при завершении транзакции
has connects => (is => 'ro', isa => ArrayRef, lazy => 0, default => sub {+[]});

# Добавляет dbh к транзакции
sub add_connect {
	my ($self, $connect) = @_;
	push @{$self->{connects}}, $connect;
	$self
}

# Комитит
sub commit {
	my ($self) = @_;
	$self->adapter->commit($self);
	$self->{connects} = ();
	$self
}

# Откатывает
sub rollback {
	my ($self) = @_;
	$self->adapter->commit($self);
	$self->{connects} = ();
	$self
}

1;