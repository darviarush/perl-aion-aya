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

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Transaction - transaction for Aion::Aya

=head1 VERSION

0.0.0

=head1 SYNOPSIS

etc/include.yml file:

	aion:
	  eon:
	    Aion::Aya::Adapter:
	      class: Aion::Aya::Adapter::MemAdapter
	    CHI:
	      class: CHI
	      arguments:
	        driver: None



	use aliased 'Aion::Aya::Appearance';
	use aliased 'Liberia::Storage::Author::Author';
	use aliased 'Liberia::Storage::Author::AuthorBox';
	
	my $appearance = Appearance->new;
	
	{
	    my $tx = $appearance->transaction;
	
	    my $author = Author->new(name => 'A.Rudazov');
	    $appearance->persist($author)->flush;
	    
	    $tx->commit;
	}
	
	AuthorBox->find_one_by_name('A.Rudazov')->id # -> 1
	
	{
	    my $tx = $appearance->transaction;
	
	    my $author = Author->new(name => 'Zero');
	    $appearance->persist($author)->flush;
	    
	    $tx->rollback;
	}
	
	AuthorBox->find_one_by_name('Zero') # -> undef

=head1 DESCRIPTION

C<Aion::Aya::Transaction> is a database transaction bound to the current fiber (C<Coro>). There can only be one active transaction on a single fiber at a time.

The transaction is declared in the entity manager (C<Aion::Aya::Appearance>). While it is alive, all calls to the database in the current fiber are included in it. It must be completed with a call to C<commit> or C<rollback>. If a variable with a transaction leaves the scope without C<commit>, C<rollback> will automatically trigger.

A transaction is associated with its adapter: when created, it calls C<begin_transaction($self)> on the adapter, and the adapter stores it under the address of the current fiber. All connections (C<DBH>) that will be open in this fiber during the lifetime of the transaction are added to it - so that C<commit>/C<rollback> applies to all work within the transaction.

=head1 STEP BY STEP

Open transaction:

 my $tx = $appearance->transaction;

Do the necessary work - for example, save several objects (all this happens within the transaction):

 $appearance->persist($book)->flush;

Commit changes if everything went well:

 $tx->commit;

Or cancel the changes:

 $tx->rollback;

=head1 INIT

By default, C<Aion::Aya::Appearance> has an adapter connected through the eons container (C<Aion::Pleroma>), for example an in‑memory driver. The transaction uses exactly the entity manager adapter from which it was received.

Below are two typical scenarios: B<successful save> (with C<commit>) and B<rollback> (with C<rollback>).

Let there be an author entity with a primary key and auto-increment:

File lib/Liberia/Storage/Author/Author.pm:

	package Liberia::Storage::Author::Author;
	use common::sense;
	use Aion::Aya;
	
	# Authors of the Liberia
	presents 'authors';
	
	# The identifier
	has id => (is => 'ro', isa => Nat, pk => 1, next => -identity);
	
	# Name of the author
	has name => (is => 'ro', isa => NonEmptyStr, col => 1, unique => 1);
	
	1;

And its repository:

File lib/Liberia/Storage/Author/AuthorBox.pm:

	package Liberia::Storage::Author::AuthorBox;
	use common::sense;
	use Aion::Aya::Box;
	
	for_box 'Liberia::Storage::Author::Author';
	
	# Получить автора по имени
	sub find_one_by_name {
		my ($self, $name) = @_;
	
		$self->query_builder->filter(name => $name)->first;
	}
	
	1;

=head1 METHODS

=head2 commit

Completes a transaction by committing it (C<commit> all open connections) and removing it from the adapter state.

	use common::sense;
	
	use aliased 'Aion::Aya::Appearance';
	use aliased 'Liberia::Storage::Author::Author';
	
	my $appearance = Appearance->new;
	my $tx = $appearance->transaction;
	
	my $author = Author->new(name => 'Tolstoy L.N.');
	$appearance->persist($author)->flush;
	
	$tx->commit;
	
	AuthorBox->find_one_by_name('Tolstoy L.N.')->id # -> 3

=head2 rollback

Completes a transaction by rolling it back (C<rollback> of all open connections).

	use common::sense;
	
	use aliased 'Aion::Aya::Appearance';
	use aliased 'Liberia::Storage::Author::Author';
	
	my $appearance = Appearance->new;
	my $tx = $appearance->transaction;
	
	my $author = Author->new(name => 'Dostoevsky F.M.');
	$appearance->persist($author)->flush;
	
	$tx->rollback;
	
	AuthorBox->find_one_by_name('Dostoevsky F.M.') # -> undef

=head1 EXAMPLES

If the variable storing the transaction is not committed, then when destroyed it will cause C<rollback>:

	use common::sense;
	
	use aliased 'Aion::Aya::Appearance';
	use aliased 'Liberia::Storage::Author::Author';
	
	sub create_attempt {
		my ($appearance, $name) = @_;
	
		my $tx = $appearance->transaction;
		my $author = Author->new(name => $name);
		$appearance->persist($author)->flush;
	}
	
	my $appearance = Appearance->new;
	create_attempt($appearance, 'Chekhov A.P.');
	
	AuthorBox->find_one_by_name('Chekhov A.P.') # -> undef

A transaction opened inside another will throw an exception:

	{
	    my $tx = $appearance->transaction;
	
	    $appearance->transaction # @-> Transaction beginned!
	
	    $tx->rollback;
	}

=head1 GOTCHAS

=over

=item * The transaction is tied to the current fiber; do not transfer it to another fiber.

=item * Only one transaction is open at a time in one fiber - a second attempt to C<begin_transaction> on the same fiber will throw an exception.

=item * The transaction should be completed explicitly (C<commit>/C<rollback>); Relying on automatic rollback when leaving scope is acceptable, but it is better not to delay the transaction.

=back

=head1 SUBROUTINES

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
