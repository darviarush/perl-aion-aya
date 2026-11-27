# NAME

Aion::Aya::Query::Join - соединение с другой таблицей

# SYNOPSIS

```perl
package Storage::Book::Join {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
	has user => (is => 'ro', isa => Object['Storage::User::Join'], ref => 1);
}

package Storage::User::Join {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'users';

	has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
	has name => (is => 'ro', isa => Str, col => 1);
}

use aliased 'Aion::Aya::Query::Join' => 'xJoin';

my $join = xJoin->new(
	join => 'left',
	model => 'Storage::Book::Join',
	field => 'user',
	from_alias => 'b',
	to_alias => 'u',
);

$join->join       # -> 'left'
$join->model      # -> 'Storage::Book::Join'
$join->field      # -> 'user'
$join->from_alias # -> 'b'
$join->to_alias   # -> 'u'

my $inner = xJoin->new(join => 'inner', model => 'Storage::Book::Join', field => 'user', from_alias => 'b', to_alias => 'u');

$inner->join # -> 'inner'

# Тип соединения ограничен inner и left
xJoin->new(join => 'outer', model => 'Storage::Book::Join', field => 'user', from_alias => 'b', to_alias => 'u') # @-> Set feature join must have the type
```

# DESCRIPTION

`Join` описывает одно соединение в `SELECT`. Список соединений хранит `Aion::Aya::Query` в фиче `join`.

`Join` — чистые данные: никакого SQL здесь нет. Как именно выглядит соединение, решает трансформер (SQL, Elastic и т. п.). Из этих данных можно собрать, например, `LEFT JOIN users u ON u.id = b.user_id`:

- `model` — класс модели-источника, у которой есть `ref`-поле `field` (здесь `Storage::Book::Join::user`);
- `field` — имя этого `ref`-поля;
- `from_alias` — псевдоним таблицы-источника в текущем запросе (`b`);
- `to_alias` — псевдоним присоединяемой таблицы (`u`);
- `join` — тип соединения (`inner` или `left`).

Результирующая модель получается из источника: `Model->get_ref(Model->get($join->model)->feature($join->field))`. Имя таблицы и имена колонок для `ON` также получает трансформер.

Класс подключается через `aliased` под именем `xJoin`: `Join` — ещё и тип-функция в `Aion::Types`, и в пакете с `use Aion` голое `Join->new` распознаётся как вызов прототипа.

Тип соединения ограничен значениями `inner` и `left`; любое другое бросает исключение в конструкторе.

# FEATURES

## join

Тип соединения: `inner` или `left`.

## model

Класс модели-источника, чьё `ref`-поле участвует в соединении.

## field

Имя `ref`-поля в модели `model`. По нему определяется результирующая модель и колонка источника.

## from_alias

Псевдоним таблицы-источника в текущем запросе.

## to_alias

Псевдоним присоединяемой таблицы.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Join module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
