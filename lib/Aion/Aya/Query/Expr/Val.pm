package Aion::Aya::Query::Expr::Val;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

has value => (is => 'ro');

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Expr::Val - литеральное значение в выражении запроса

=head1 SYNOPSIS

	use Aion::Aya::Query::Expr::Val;
	
	my $val = Aion::Aya::Query::Expr::Val->new(value => 42);
	
	$val->value # -> 42
	$val->isa('Aion::Aya::Query::Expr') # -> 1

=head1 DESCRIPTION

C<Val> — лист дерева выражений: литерал, который попадёт в SQL как есть. Значение не проверяется по типу, поэтому сюда кладут и строки, и числа, и C<undef>.

Литералы в дерево подставляет C<Aion::Aya::Query::Expr>: в операциях вида C<$field + 1> правый операнд C<1> автоматически оборачивается в C<Val>.

=head1 FEATURES

=head2 value

Значение литерала.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Expr::Val module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
