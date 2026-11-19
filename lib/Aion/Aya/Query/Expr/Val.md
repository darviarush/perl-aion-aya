# NAME

Aion::Aya::Query::Expr::Val - литеральное значение в выражении запроса

# SYNOPSIS

```perl
use Aion::Aya::Query::Expr::Val;

my $val = Aion::Aya::Query::Expr::Val->new(value => 42);

$val->value # -> 42
$val->isa('Aion::Aya::Query::Expr') # -> 1
```

# DESCRIPTION

`Val` — лист дерева выражений: литерал, который попадёт в SQL как есть. Значение не проверяется по типу, поэтому сюда кладут и строки, и числа, и `undef`.

Литералы в дерево подставляет `Aion::Aya::Query::Expr`: в операциях вида `$field + 1` правый операнд `1` автоматически оборачивается в `Val`.

# FEATURES

## value

Значение литерала.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Expr::Val module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
