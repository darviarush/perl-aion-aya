# NAME

Aion::Aya::Query::Order - направление сортировки

# SYNOPSIS

```perl
use Aion::Aya::Query::Order;

my $order = Aion::Aya::Query::Order->new(desc => 1);

$order->desc # -> 1

my $asc = Aion::Aya::Query::Order->new;

$asc->desc # -> undef
```

# DESCRIPTION

`Order` указывает направление сортировки: по возрастанию (`desc` ложно) или по убыванию (`desc` истинно).

Сейчас `Aion::Aya::Query` хранит сортировки как пары «выражение — строка `ASC`/`DESC`», а `Order` — задел на замену строки объектом. Используйте `Order`, если нужен объектный вид направления без привязки к диалекту.

# FEATURES

## desc

Сортировка по убыванию.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Order module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
