# NAME

Aion::Aya::Query::Join - соединение с другой таблицей

# SYNOPSIS

```perl
use aliased 'Aion::Aya::Query::Join' => 'xJoin';

my $join = xJoin->new(field => 'author', alias => 'a', join => 'left');

$join->field # -> 'author'
$join->alias # -> 'a'
$join->join  # -> 'left'

my $inner = xJoin->new(field => 'author', alias => 'a', join => 'inner');

$inner->join # -> 'inner'

# Тип соединения ограничен inner и left
xJoin->new(field => 'author', alias => 'a', join => 'outer') # @-> Set feature join must have the type
```

# DESCRIPTION

`Join` описывает, с какой таблицей и как соединяться в `SELECT`. Список соединений хранит `Aion::Aya::Query` в фиче `join`.

Класс подключается через `aliased` под именем `xJoin`: `Join` — ещё и тип-функция в `Aion::Types`, и в пакете с `use Aion` голое `Join->new` распознаётся как вызов прототипа.

Тип соединения ограничен значениями `inner` и `left`; любое другое бросает исключение в конструкторе.

# FEATURES

## field

Поле сущности, по которому идёт соединение.

## alias

Псевдоним присоединяемой таблицы.

## join

Тип соединения: `inner` или `left`.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Join module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
