package Aion::Aya::Migration;

use common::sense;

use Guard qw/guard/;

use Aion;

# Адаптер
req adapter => (is => 'ro', isa => Object['Aion::Aya::Adapter']);

# Выполняет sql
sub add_sql :Isa(Me => Str => PositiveInt) {
	my ($self, $sql) = @_;

	my $adapter = $self->adapter;
	my $dbh = $adapter->connect;
	my $dbh_guard = guard { $adapter->finish($dbh); };
	$adapter->do($dbh, $sql);
}

# Возвращает итератор
sub iter_sql :Isa(Me => Str => Object['Aion::Aya::Iterator']) {
	my ($self, $sql) = @_;

	$self->adapter->raw_iterator($sql);
}

1;