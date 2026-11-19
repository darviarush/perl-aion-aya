package Aion::Aya::Query::Expr::Op;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

has op => (is => 'ro', isa => Str);
has left => (is => 'ro', isa => 'Aion::Aya::Query::Expr');
has right => (is => 'ro', isa => 'Aion::Aya::Query::Expr');

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Expr::Op - бинарная операция над двумя выражениями

=head1 SYNOPSIS

	use Aion::Aya::Query::Expr::Val;
	use Aion::Aya::Query::Expr::Op;
	
	my $left  = Aion::Aya::Query::Expr::Val->new(value => 1);
	my $right = Aion::Aya::Query::Expr::Val->new(value => 2);
	
	my $op = Aion::Aya::Query::Expr::Op->new(op => '+', left => $left, right => $right);
	
	$op->op            # -> '+'
	$op->left->value   # -> 1
	$op->right->value  # -> 2
	$op->isa('Aion::Aya::Query::Expr') # -> 1
	
	# Обычно узел порождают перегрузки
	my $sum = $left + $right;
	
	ref $sum           # -> 'Aion::Aya::Query::Expr::Op'
	$sum->op           # -> '+'

=head1 DESCRIPTION

Узел дерева выражений для бинарной операции: C<left op right>. Создаётся вручную редко — обычно его порождают перегрузки операторов в C<Aion::Aya::Query::Expr>.

=head1 FEATURES

=head2 op

Оператор: C<+>, C<->, C<*>, C</>, C<%>, C<**>, C<=>, C<!=>, C<< E<lt> >>, C<< E<gt> >>, C<< E<lt>= >>, C<< E<gt>= >>, C<||>, C<AND>, C<OR>.

=head2 left

Левый операнд — выражение.

=head2 right

Правый операнд — выражение.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Expr::Op module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
