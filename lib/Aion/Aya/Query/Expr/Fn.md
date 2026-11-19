# NAME

Aion::Aya::Query::Expr::Fn - вызов функции базы в выражении

# SYNOPSIS

```perl
use Aion::Aya::Query::Expr::Val;
use Aion::Aya::Query::Expr::Fn;

my $arg = Aion::Aya::Query::Expr::Val->new(value => 'title');

my $fn = Aion::Aya::Query::Expr::Fn->new(name => 'COUNT', args => [$arg]);

$fn->name           # -> 'COUNT'
$fn->args->[0]->value # -> 'title'
$fn->isa('Aion::Aya::Query::Expr') # -> 1

# Несколько аргументов
my $coalesce = Aion::Aya::Query::Expr::Fn->new(
	name => 'COALESCE',
	args => [
		Aion::Aya::Query::Expr::Val->new(value => 1),
		Aion::Aya::Query::Expr::Val->new(value => 0),
	],
);

scalar(@{$coalesce->args}) # -> 2

# Пустой список аргументов допустим
my $now = Aion::Aya::Query::Expr::Fn->new(name => 'NOW', args => []);

scalar(@{$now->args}) # -> 0
```

# DESCRIPTION

Узел дерева выражений для вызова функции базы: `name(args...)`. Аргументы — любые выражения (`Val`, `Field`, другие `Fn`), список может быть пустым.

# FEATURES

## name

Имя функции базы (`COUNT`, `COALESCE`, `LOWER`).

## args

Список аргументов — выражений.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Expr::Fn module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
