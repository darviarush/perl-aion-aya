# NAME

Aion::Aya::Query::Expr::UOp - унарная операция над выражением

# SYNOPSIS

```perl
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
```

# DESCRIPTION

Узел дерева выражений для унарной операции: `op exp`. Обычно создаётся перегрузками в `Aion::Aya::Query::Expr`.

# FEATURES

## op

Оператор: `-` (отрицание) или `NOT` (логическое отрицание).

## exp

Операнд — выражение.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Expr::UOp module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
