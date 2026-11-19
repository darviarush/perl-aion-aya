# NAME

Aion::Aya::Query::Expr::Op - бинарная операция над двумя выражениями

# SYNOPSIS

```perl
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
```

# DESCRIPTION

Узел дерева выражений для бинарной операции: `left op right`. Создаётся вручную редко — обычно его порождают перегрузки операторов в `Aion::Aya::Query::Expr`.

# FEATURES

## op

Оператор: `+`, `-`, `*`, `/`, `%`, `**`, `=`, `!=`, `<`, `>`, `<=`, `>=`, `||`, `AND`, `OR`.

## left

Левый операнд — выражение.

## right

Правый операнд — выражение.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Expr::Op module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
