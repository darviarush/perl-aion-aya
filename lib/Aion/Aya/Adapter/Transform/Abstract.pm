package Aion::Aya::Adapter::Transform::Abstract;

use common::sense;

use aliased 'Aion::Aya::Query';

use Aion;

# Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic)
sub transform :Isa(Me => Query => Any);

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Adapter::Transform::Abstract - contract for turning Aion::Aya::Query into a database query (Mysql, Elastic, etc)

=head1 SYNOPSIS

	package ExEntity {
		use Aion with => 'Aion::Aya';
	}
	
	package ExTransform {
		use aliased 'Aion::Aya::Query';
	
		use Aion;
	
		with 'Aion::Aya::Adapter::Transform::Abstract';
	
		sub transform :Isa(Me => Query => Any) {
			my ($self, $query) = @_;
			+{ x => 123 }
		}
	}
	
	use aliased 'Aion::Aya::Query';
	
	my $transformator = ExTransform->new;
	my $query = Query->new(from => 'ExEntity');
	$transformator->transform($query) # --> +{ x => 123 }

=head1 DESCRIPTION

Aion::Aya::Adapter::Transform::Abstract - a contract for turning Aion::Aya::Query into a database query (Mysql, Elastic, etc).

=head1 SUBROUTINES

=head2 transform ()

Transforms a query into an intermediate representation (for example, SQL or a structure in Elastic).

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Adapter::Transform::Abstract module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
