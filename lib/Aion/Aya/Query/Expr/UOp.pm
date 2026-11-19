package Aion::Aya::Query::Expr::UOp;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

has op => (is => 'ro', isa => Str);
has exp => (is => 'ro', isa => 'Aion::Aya::Query::Expr');

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Expr::UOp - унарная операция над выражением

=head1 SYNOPSIS

	use Aion::Aya::Query::Expr::Val;
	use Aion::Aya::Query::Expr::UOp;
	
	my $exp = Aion::Aya::Query::Expr::Val->new(value => 5);
	my $neg = Aion::Aya::Query::Expr::UOp->new(op => '-', exp => $exp);
	
	$neg->op       # -> '-'
	$neg->exp->value # -> 5
	$neg->isa('Aion::Aya::Query::Expr') # -> 1
	
	# Обычно узел порождают перегрузки
	my $auto_neg = -$exp;
	my $auto_not = ~$exp;
	
	ref $auto_neg     # -> 'Aion::Aya::Query::Expr::UOp'
	$auto_neg->op     # -> '-'
	$auto_not->op     # -> 'NOT'

=head1 DESCRIPTION

Узел дерева выражений для унарной операции: C<op exp>. Обычно создаётся перегрузками в C<Aion::Aya::Query::Expr>.

=head1 FEATURES

=head2 op

Оператор: C<-> (отрицание) или C<NOT> (логическое отрицание).

=head2 exp

Операнд — выражение.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Expr::UOp module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
