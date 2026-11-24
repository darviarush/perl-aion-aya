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

# Сессия итератора: открытое соединение (dbh), подготовленный запрос (sth) и сам запрос или SQL
has session => (is => 'ro');

# Следующее значение или undef, если строки закончились
sub next {
	my ($self) = @_;
	$self->{adapter}->next($self->{session});
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Iterator - cursor over query result lines with overloads for convenient enumeration

=head1 SYNOPSIS

	package Adapter::Mock {
		our @ISA = 'Aion::Aya::Adapter';
	
		sub new { bless {}, shift }
	
		sub next { my ($self, $session) = @_; $session->{rows}[$session->{i}++] }
	}
	
	use Aion::Aya::Iterator;
	
	Aion::Aya::Iterator->Aion::initialize;
	
	my $adapter = Adapter::Mock->new;
	my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [1, 2, 3]});
	
	$iterator->next # -> 1
	$iterator->next # -> 2
	$iterator->next # -> 3
	$iterator->next # -> undef

=head1 DESCRIPTION

C<Aion::Aya::Iterator> is a thin wrapper over the B<session> adapter. The iterator itself knows nothing about the base: it stores C<adapter> and C<session>, and the adapter does all the work.

C<session> for an adapter on C<DBI> (C<Aion::Aya::Adapter::Iterator::DBI>) is a hash that the adapter fills lazily as C<next> is called:

=over

=item * C<query> — C<Aion::Aya::Query> object, from which the transformer makes SQL (for C<iterator>);

=item * C<sql> — ready SQL (for C<raw_iterator>);

=item * C<dbh> — connection, taken from the adapter pool or opened again;

=item * C<sth> — prepared and launched request; when there are no more lines, C<sth> and C<dbh> are removed from the session and returned to the pool.

=back

Therefore, an iterator is a B<one-time cursor>: the session moves forward, but you cannot return to lines that have already been read.

C<Iterator> overloads three operations:

=over

=item * B<< C<@{ }> >> — collect all remaining lines into an array;

=item * B<< C<&{ }> >> — get a generator function that returns C<next> every time it is called;

=item * B<< C<< E<lt> E<gt> >> >> is C<next> (in scalar context).

=back

The objects that the iterator returns depend on the source:

=over

=item * for C<iterator>, the adapter creates an entity of class C<< $query-E<gt>from >> - B<or> a proxy successor, if the line has alias fields that the entity does not have (see C<Aion::Aya::Adapter>);

=item * for C<raw_iterator> a “raw” string is given - C<HashRef> with column names.

=back

=head1 FEATURES

=head2 adapter

Required adapter. The requirement is weakened (C<< is =E<gt> 'ro*' >>), that is, the iterator holds a B<weak> reference to the adapter: the adapter must live separately, otherwise it will disappear and C<next> will fall.

=head2 session

Iterator session. Gives access to the same query state along which the lines go: C<dbh>, C<sth> and the original C<query>/C<sql>. The iterator passes it to C<< adapter-E<gt>next >>, so it is also a state unit for the adapter protocol.

=head1 METHODS

=head2 next

Returns the next line via C<< $self-E<gt>{adapter}-E<gt>next($self-E<gt>{session}) >> or C<undef> when there are no more lines.

This is the method that all overloads call; implements its adapter.

	my $adapter = Adapter::Mock->new;
	my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['one', 'two', 'three']});
	
	my $first = $iterator->next;
	$first              # -> 'one'
	$iterator->next     # -> 'two'
	$iterator->next     # -> 'three'
	$iterator->next     # -> undef

=head1 EXAMPLES

=head2 next

	my $adapter = Adapter::Mock->new;
	my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [1, 2, 3]});
	
	my @values;
	while(my $value = $iterator->next) { push @values, $value }
	
	"@values"       # -> "1 2 3"
	
	$iterator->next # -> undef
	$iterator->next # -> undef

=head2 @{ }

	my $adapter = Adapter::Mock->new;
	my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['a', 'b', 'c']});
	
	my $rows = \@$iterator;
	
	ref $rows           # -> 'ARRAY'
	scalar @$rows       # -> 3
	"@$rows"            # -> "a b c"
	
	scalar @{$iterator} # -> 0

=head2 &{ }

	my $adapter = Adapter::Mock->new;
	my $generator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [10, 20, 30]});
	
	$generator->()   # -> 10
	$generator->()   # -> 20
	$generator->()   # -> 30
	$generator->()   # -> undef
	
	ref $generator   # -> 'Aion::Aya::Iterator'

=head2 < >

	my $adapter = Adapter::Mock->new;
	my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['x', 'y']});
	
	my $first = <$iterator>;
	$first           # -> 'x'
	<$iterator>      # -> 'y'
	<$iterator>      # -> undef

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Iterator module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
