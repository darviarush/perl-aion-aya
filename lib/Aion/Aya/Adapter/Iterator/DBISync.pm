package Aion::Aya::Adapter::Iterator::DBISync;

use common::sense;

use aliased 'Aion::Aya::Iterator';
use aliased 'Aion::Aya::Query';

use Aion -role;

with 'Aion::Aya::Adapter';

has dsn => (is => 'ro', isa => Str);
has login => (is => 'ro', isa => Maybe[Str]);
has password => (is => 'ro', isa => Maybe[Str]);
has attr => (is => 'ro', isa => HashRef);

# Порождает итератор
sub iterator :Isa(Me => Object[Query] => Object[Iterator]) {
	my ($self, $query) = @_;
	Iterator->new(adapter => $self, session => { query => $query });
}

# Следующая строка из сессии
sub next :Isa(Me => HashRef => Any) {
	my ($self, $session) = @_;

	$session->{dbh} //= DBI->connect_cached($self->dsn, $self->login, $self->password, $self->attr);
	$session->{sth} //= do {
		my $query = $self->transform($session->{query});
		my $sth = $session->{dbh}->prepare($query);
		$sth->execute;
		$sth
	};

	my $row = $session->{sth}->fetchrow_hashref;
	if(defined $row) {
		$session->{query}->from->new(%$row);
	} else {
		$session->{sth}->finish;
		$row
	}
}

1;