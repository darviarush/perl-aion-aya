# NAME

Aion::Aya::QueryBuilder - пошаговая сборка запроса поверх Aion::Aya::Query

# SYNOPSIS

```perl
package Storage::Book::Builder {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has id    => (is => 'ro', isa => Int, pk => 1, col => 1);
	has title => (is => 'ro', isa => Str, col => 1);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Builder');

# Алиас главной сущности выводится из имени класса
$qb->_from  # -> 'Storage::Book::Builder'
$qb->_alias # -> 'S'

# Каждый шаг возвращает новый QueryBuilder — можно строить цепочку
my $query = $qb->filter(title => 'Clarissa')->limit(10);

ref $query                    # -> 'Aion::Aya::QueryBuilder'
$query->_query->filter->op    # -> '='
$query->_query->filter->left->name   # -> 'title'
$query->_query->filter->left->alias  # -> 'S'
$query->_query->filter->right->value # -> 'Clarissa'
$query->_query->{limit}       # -> 10

# Исходный билдер не изменяется
$qb->_query->{limit} # -> undef
```

# DESCRIPTION

`QueryBuilder` — надстройка над `Aion::Aya::Query` для пошаговой сборки запроса. Каждый метод возвращает **новый `QueryBuilder`** (через `clone`), а не меняет текущий и не возвращает голый `Query`. Поэтому шаги можно объединять в цепочку: `$qb->filter(...)->limit(10)->offset(5)`, а исходный `$qb` остаётся нетронутым.

Сам запрос доступен у результата в фиче `_query`. Имя главной сущности задаётся `_from`; `_alias` — псевдоним, выводимый из имени класса: имя режется по одинарным `_`, от каждого непустого куска берётся первая буква. `::` сегменты не делит, поэтому `Storage::Book::Builder` даёт `S`, а `Book_A_B` — `BAB`. Псевдонимы присоединённых сущностей хранит `_aliases`.

Условия фильтрации строятся из пар «поле => значение». Поле без `__`/`.` относится к главной сущности, поле вида `alias__field`/`alias.field` — к присоединённой. Если последний сегмент — оператор (`eq`, `ne`, `le`, `ge`, `gt`, `lt`, `like`, `unlike`, `isnull`, `isnotnull`), он становится оператором сравнения, иначе используется `=`.

# SUBROUTINES

## clone (%opt)

Клонирует билдер: запрос клонируется отдельно, алиасы копируются в новый хеш. Опции:

- `_query` — изменения для `Query->clone` (`{ operation => ..., limit => ... }`);
- `aliases` — добавляемые/переопределяемые алиасы;
- `self` — произвольные изменения самого билдера.

```perl
package Storage::Book::Clone {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has title => (is => 'ro', isa => Str, col => 1);
}

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Clone');

my $copy = $qb->clone(_query => { limit => 5 });

ref $copy               # -> 'Aion::Aya::QueryBuilder'
$copy->_query->{limit}  # -> 5
$qb->_query->{limit}    # -> undef
```

## filter (@expr)

Задаёт условие `WHERE` из пар «поле => значение»; пары соединяются через `AND`. Оператор задаётся вторым `__` в имени поля.

```perl
package Storage::Book::Filter {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has title => (is => 'ro', isa => Str, col => 1);
}

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');

my $query = $qb->filter(title => 'Clarissa');

$query->_query->filter->op           # -> '='
$query->_query->filter->left->name   # -> 'title'
$query->_query->filter->right->value # -> 'Clarissa'

my $two = $qb->filter(title => 'Clarissa', title => 7);
$two->_query->filter->op # -> 'AND'

$qb->filter(title__like => '%ari%')->_query->filter->op # -> 'like'
$qb->filter(title__ne => 'x')->_query->filter->op       # -> 'ne'
```

## and_filter (@expr)

Добавляет условие через `AND`. Если предыдущего условия нет, ставит новое без `AND`.

```perl
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');

$qb->and_filter(title => 'x')->_query->filter->op # -> '='

my $narrowed = $qb->filter(title => 'x')->and_filter(title => 'y');

$narrowed->_query->filter->op       # -> 'AND'
$narrowed->_query->filter->left->op # -> '='
```

## or_filter (@expr)

Добавляет условие через `OR`. Если предыдущего условия нет, ставит новое без `OR`.

```perl
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');

$qb->or_filter(title => 'x')->_query->filter->op # -> '='

$qb->filter(title => 'x')->or_filter(title => 'y')->_query->filter->op # -> 'OR'
```

## annotate (@select)

Добавляет поля в выборку: `Expr => Str` или просто имя поля (превращается в поле главной сущности).

```perl
package Storage::Book::Annotate {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has title => (is => 'ro', isa => Str, col => 1);
}

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

my $query = $qb->annotate('title');

scalar(@{$query->_query->select})    # -> 2
$query->_query->select->[1]          # -> 'title'
$query->_query->select->[0]->name    # -> 'title'
$query->_query->select->[0]->alias   # -> 'S'
```

## add_annotate (@select)

Добавляет поля поверх уже отобранных.

```perl
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

my $query = $qb->annotate('title')->add_annotate('id');

scalar(@{$query->_query->select}) # -> 4
```

## group_by (@groups)

Задаёт `GROUP BY`.

## add_group_by (@groups)

Добавляет выражения в `GROUP BY` поверх уже заданных.

```perl
use aliased 'Aion::Aya::Query::Expr::Field';

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
my $t = Field->new(alias => 'S', name => 'title', entity => 'Storage::Book::Annotate');

my $query = $qb->group_by($t)->add_group_by($t);

scalar(@{$query->_query->group_by}) # -> 2
```

## having (@expr)

Задаёт `HAVING` — фильтр после группировки.

## and_having (@expr)

Дополняет `HAVING` через `AND`.

## or_having (@expr)

Дополняет `HAVING` через `OR`.

```perl
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

$qb->having(title => 'x')->_query->having->op # -> '='
$qb->having(title => 'x')->and_having(title => 'y')->_query->having->op # -> 'AND'
```

## order_by (@orders)

Задаёт `ORDER BY`. Значения — пары «выражение/поле => `ASC`|`DESC`».

## add_order_by (@orders)

Добавляет сортировку поверх уже заданной.

```perl
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
my $t = Field->new(alias => 'S', name => 'title', entity => 'Storage::Book::Annotate');

my $query = $qb->order_by($t => 'ASC')->add_order_by($t => 'DESC');

scalar(@{$query->_query->order_by}) # -> 4
```

## offset ($offset)

Задаёт смещение выборки.

## limit ($limit)

Задаёт ограничение количества строк.

```perl
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

my $query = $qb->limit(10)->offset(2);

$query->_query->{limit}  # -> 10
$query->_query->{offset} # -> 2
```

## delete ()

Переключает запрос на операцию `DELETE`.

## update (@update)

Переключает запрос на `UPDATE`, переданные поля становятся секцией `SET`.

## insert (@insert)

Переключает запрос на `INSERT`, переданные поля становятся секцией `SET`.

## inner_join ($field, $alias)

Присоединяет сущность внутренним (`INNER`) объединением.

## left_join ($field, $alias)

Присоединяет сущность левым (`LEFT`) объединением.

Оба метода разбирают описание через общий `_make_join` и поддерживают формы:

- `'user as u'` — поле `user` **главной** сущности, алиас `u`;
- `user => 'u'` — то же; у алиаса отбрасывается ведущее `-` (`user => '-u'`);
- `'u.admin as a'` — поле `admin` уже присоединённого алиаса `u`, алиас `a`;
- `u__admin => 'a'` — то же в форме «алиас__поле => алиас».

Поле должно быть объявлено как `ref`; в `Join` кладётся модель-источник и её `ref`-поле. Имя таблицы и колонки для `ON` получает трансформер.

```perl
package Storage::Book::Join {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has id      => (is => 'ro', isa => Int, pk => 1, col => 1);
	has user    => (is => 'ro', isa => Object['Storage::User::Join'], ref => 1);
}

package Storage::User::Join {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'users';

	has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
	has name => (is => 'ro', isa => Str, col => 1);
}

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Join');

my $joined = $qb->left_join('user as u');
my $join = $joined->_query->join->[0];

$join->join       # -> 'left'
$join->model      # -> 'Storage::Book::Join'
$join->field      # -> 'user'
$join->from_alias # -> 'S'
$join->to_alias   # -> 'u'

# Новый алиас регистрируется, по нему можно присоединять дальше
$joined->_aliases->{u} # -> 'Storage::User::Join'

# Парная форма, тире отбрасывается
my $inner = $qb->inner_join(user => '-u');
$inner->_query->join->[0]->to_alias # -> 'u'
$inner->_query->join->[0]->join     # -> 'inner'

# Неизвестное поле
$qb->inner_join('zzz as a') # @-> Not zzz field
```

## iter ()

Возвращает итератор строк выборки.

## iter_or_array ()

Возвращает массив в списковом контексте и итератор в скалярном.

## as_array ()

Возвращает массив строк выборки. Только в списковом контексте.

## first ()

Возвращает единственную строку выборки; если строк больше одной — исключение.

## scalar ($field)

Возвращает значение одного поля первой строки. Ведущий `-` в имени поля отбрасывается.

## column ($field)

Возвращает значения поля по всем строкам: список в списковом контексте, ссылка на массив — в скалярном.

## count ()

Возвращает количество строк выборки — обёртка над агрегатом `count` базы.

## sum ()

Возвращает сумму по выборке — агрегат `sum`.

## avg ()

Возвращает среднее арифметическое по выборке — агрегат `avg`.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::QueryBuilder module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
