package Aion::Aya::Iterator;
# Итератор с результатом 

use common::sense;

use overload fallback => 0,
	'@{}' => sub {
		my ($self) = @_;
		my @rows;
		while(my $row = $self->next) { push @rows, $row }
		\@rows },
	'&{}' => sub {
		my ($self) = @_;
        sub { $self->next } },
	'<>' => sub { shift->next },
;

use Aion -role;

# Адаптер
has adapter => (is => 'ro*', isa => 'Aion::Aya::Adapter');

# Соединение с БД
has session => (is => 'ro');

# Следующее значение
sub next {
	my ($self) = @_;
	$self->{adapter}->next($self->{session});
}

1;