# NAME

Aion::Aya::Query::Expr - выражение запроса и перегрузки операторов для его сборки

# SYNOPSIS

```perl
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
```

# DESCRIPTION

`Expr` — роль, общая для всех узлов дерева выражений: `Val`, `Field`, `Fn`, `Op`, `UOp`. Сама по себе не инстанцируется.

Главная ценность роли — `overload`: любой узел можно собирать обычными перлами вместо ручного построения `Op`/`UOp`. Справа может стоять что угодно: если это не `Expr`, значение оборачивается в `Val` автоматически.

| Perl | В дереве | Узел |
|---|---|---|
| `$a + $b` | `a + b` | `Op` |
| `$a - $b` | `a - b` | `Op` |
| `$a * $b` | `a * b` | `Op` |
| `$a / $b` | `a / b` | `Op` |
| `$a % $b` | `a % b` | `Op` |
| `$a ** $b` | `a ** b` | `Op` |
| `$a == $b` | `a = b` | `Op` |
| `$a != $b` | `a != b` | `Op` |
| `$a < $b` | `a < b` | `Op` |
| `$a > $b` | `a > b` | `Op` |
| `$a <= $b` | `a <= b` | `Op` |
| `$a >= $b` | `a >= b` | `Op` |
| `$a . $b` | `a \|\| b` | `Op` |
| `$a & $b` | `a AND b` | `Op` |
| `$a \| $b` | `a OR b` | `Op` |
| `-$a` | `- a` | `UOp` |
| `~$a` | `NOT a` | `UOp` |

Порядок операндов учитывается: если `Expr` стоит справа (`10 - $v`), `overload` вызывает обработчик с признаком `swap`, и операнды меняются местами.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Expr module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
