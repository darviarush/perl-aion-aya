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