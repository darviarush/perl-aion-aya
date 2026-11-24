use common::sense;
use Aion with => 'Aion::Aya';
use Aion::Aya ();

package Lib::Book {
	use Aion::Types;

	main::presents 'books';
	main::has 'id' => (is => 'ro', isa => Int, pk => 1, col => 1);
	main::has 'title' => (is => 'ro', isa => Str, col => 1);
}

package main;
print "ok: ", ref(Lib::Book->new), "\n";
print "table: ", Aion::Aya::Model->get('Lib::Book')->table, "\n";
