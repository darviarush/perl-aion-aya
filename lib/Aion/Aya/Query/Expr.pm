package Aion::Aya::Query::Expr;

use common::sense;

require Aion::Aya::Query::Expr::Op;
require Aion::Aya::Query::Expr::UOp;
require Aion::Aya::Query::Expr::Val;

use overload fallback => 0,
	# Арифметические
    "neg"  => sub { Aion::Aya::Query::Expr::UOp->new(op => "-", exp => shift) },
    "+"  => sub { unshift @_, '+';  goto &_make_op },
    "-"  => sub { unshift @_, '-';  goto &_make_op },
    "*"  => sub { unshift @_, '*';  goto &_make_op },
    "/"  => sub { unshift @_, '/';  goto &_make_op },
    "%"  => sub { unshift @_, '%';  goto &_make_op },
    "**" => sub { unshift @_, '**'; goto &_make_op },
    
    # Сравнения
    "==" => sub { unshift @_, '=';  goto &_make_op },
    "!=" => sub { unshift @_, '!='; goto &_make_op },
    "<"  => sub { unshift @_, '<';  goto &_make_op },
    ">"  => sub { unshift @_, '>';  goto &_make_op },
    "<=" => sub { unshift @_, '<='; goto &_make_op },
    ">=" => sub { unshift @_, '>='; goto &_make_op },
    
    # Строковые
    "."  => sub { unshift @_, '||'; goto &_make_op },
    
    # Логические
    "~"  => sub { Aion::Aya::Query::Expr::UOp->new(op => 'NOT', exp => shift) },
    "&"  => sub { unshift @_, 'AND';  goto &_make_op },
    "|"  => sub { unshift @_, 'OR';  goto &_make_op },
;

sub _make_op {
	my ($op, $left, $right, $swap) = @_;

	$right = Aion::Aya::Query::Expr::Val->new(value => $right) unless UNIVERSAL::isa($right, __PACKAGE__);
	
	($left, $right) = ($right, $left) if $swap;
	
	Aion::Aya::Query::Expr::Op->new(op => $op, left => $left, right => $right);
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Expr - выражение запроса и перегрузки операторов для его сборки

=head1 SYNOPSIS

	use Aion::Aya::Query::Expr::Val;
	use Aion::Aya::Query::Expr::Field;
	
	package Storage::Book::Expr {
		use Aion;
	
		has title => (is => 'ro', isa => Str);
	}
	
	my $title = Aion::Aya::Query::Expr::Field->new(alias => 'b', name => 'title', entity => 'Storage::Book::Expr');
	
	# Арифметика: литерал справа становится Val
	my $sum = $title + 1;
	ref $sum              # -> 'Aion::Aya::Query::Expr::Op'
	$sum->op              # -> '+'
	$sum->left->name      # -> 'title'
	$sum->right->value    # -> 1
	
	# Сравнение
	my $eq = $title == 'Clarissa';
	$eq->op               # -> '='
	$eq->right->value     # -> 'Clarissa'
	
	# Унарные операции
	my $neg = -$sum;
	ref $neg              # -> 'Aion::Aya::Query::Expr::UOp'
	$neg->op              # -> '-'
	
	my $not = ~$eq;
	$not->op              # -> 'NOT'
	
	# Логика
	my $and = $eq & $neg;
	$and->op              # -> 'AND'
	
	my $or = $eq | $neg;
	$or->op               # -> 'OR'
	
	# Expr справа: операнды меняются местами
	my $sub = 10 - $sum;
	$sub->op              # -> '-'
	$sub->left->value     # -> 10
	$sub->right->op       # -> '+'

=head1 DESCRIPTION

C<Expr> — роль, общая для всех узлов дерева выражений: C<Val>, C<Field>, C<Fn>, C<Op>, C<UOp>. Сама по себе не инстанцируется.

Главная ценность роли — C<overload>: любой узел можно собирать обычными перлами вместо ручного построения C<Op>/C<UOp>. Справа может стоять что угодно: если это не C<Expr>, значение оборачивается в C<Val> автоматически.

| Perl | В дереве | Узел |
|---|---|---|
| C<$a + $b> | C<a + b> | C<Op> |
| C<$a - $b> | C<a - b> | C<Op> |
| C<$a * $b> | C<a * b> | C<Op> |
| C<$a / $b> | C<a / b> | C<Op> |
| C<$a % $b> | C<a % b> | C<Op> |
| C<$a ** $b> | C<a ** b> | C<Op> |
| C<$a == $b> | C<a = b> | C<Op> |
| C<$a != $b> | C<a != b> | C<Op> |
| C<< $a E<lt> $b >> | C<< a E<lt> b >> | C<Op> |
| C<< $a E<gt> $b >> | C<< a E<gt> b >> | C<Op> |
| C<< $a E<lt>= $b >> | C<< a E<lt>= b >> | C<Op> |
| C<< $a E<gt>= $b >> | C<< a E<gt>= b >> | C<Op> |
| C<$a . $b> | C<a \|\| b> | C<Op> |
| C<$a & $b> | C<a AND b> | C<Op> |
| C<$a \| $b> | C<a OR b> | C<Op> |
| C<-$a> | C<- a> | C<UOp> |
| C<~$a> | C<NOT a> | C<UOp> |

Порядок операндов учитывается: если C<Expr> стоит справа (C<10 - $v>), C<overload> вызывает обработчик с признаком C<swap>, и операнды меняются местами.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Expr module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
