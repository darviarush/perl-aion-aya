# NAME

Aion::Aya::QueryBuilder - пошаговая сборка запроса поверх Aion::Aya::Query

# SYNOPSIS

```perl
package Storage::Book::Builder {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Builder');

# Алиас главной сущности выводится из имени класса
$qb->_from  # -> 'Storage::Book::Builder'
$qb->_alias # -> 'S'

# Фильтр: пара «поле => значение»
my $query = $qb->filter(title => 'Clarissa');

ref $query           # -> 'Aion::Aya::Query'
$query->filter->op   # -> '='
$query->filter->left->name   # -> 'title'
$query->filter->left->alias  # -> 'S'
$query->filter->right->value # -> 'Clarissa'

# Несколько условий соединяются через AND
my $both = $qb->filter(title => 'Clarissa', author => 7);

$both->filter->op       # -> 'AND'
$both->filter->left->op # -> '='
$both->filter->right->op # -> '='
```

# DESCRIPTION

`QueryBuilder` — надстройка над `Aion::Aya::Query` для пошаговой сборки запроса. Каждый метод возвращает **новый** `Aion::Aya::Query`, а не меняет текущий: исходный `$qb` остаётся нетронутым, поэтому из одного билдера можно построить несколько независимых запросов.

Важно учитывать при использовании: методы возвращают именно `Query`, а не `QueryBuilder`. Значит цепочка вида `$qb->filter(...)->order_by(...)` не соберётся — `order_by` у `Query` — это фича, а не билдер-метод. Правильно сохранять промежуточный результат и строить следующий шаг от `$qb` или от нового билдера.

Имя главной сущности задаётся `_from`. `_alias` — псевдоним, который выводится из имени класса: имя режется по одинарным `_`, от каждого непустого куска берётся первая буква. `::` сегменты не делит, поэтому `Storage::Book::Annotate` даёт `S`, а `Book_A_B` — `BAB`. Псевдонимы присоединённых сущностей хранит `_aliases`; по ним разрешаются поля вида `alias__field`.

Условия фильтрации строятся из пар «поле => значение». Поле без `__` относится к главной сущности, поле вида `alias__field` — к присоединённой. Если последний сегмент — оператор (`eq`, `ne`, `le`, `ge`, `gt`, `lt`, `like`, `unlike`, `isnull`, `isnotnull`), он становится оператором сравнения, иначе используется `=`.

# SUBROUTINES

## filter (@expr)

Задаёт условие `WHERE`. Значения передаются парами «поле => значение», условия соединяются через `AND`.

Оператор задаётся вторым подчёркиванием в имени поля. Без оператора используется `=`. Доступны `eq`, `ne`, `le`, `ge`, `gt`, `lt`, `like`, `unlike`, `isnull`, `isnotnull`.

```perl
package Storage::Book::Filter {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');

my $query = $qb->filter(title => 'Clarissa');

$query->filter->op           # -> '='
$query->filter->left->name   # -> 'title'
$query->filter->right->value # -> 'Clarissa'

# Несколько пар
my $two = $qb->filter(title => 'Clarissa', author => 7);
$two->filter->op # -> 'AND'

# Оператор в имени поля: field__op => значение
$qb->filter(title__like => '%ari%')->filter->op  # -> 'like'
$qb->filter(title__ne => 'x')->filter->op      # -> 'ne'
$qb->filter(title__eq => 'x')->filter->op      # -> 'eq'
```

## and_filter ($expr)

Добавляет условие к уже заданному через `AND`.

```perl
package Storage::Book::AndFilter {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::AndFilter');

my $query = $qb->filter(title => 'Clarissa');
my $narrowed = $qb->filter(title => 'Clarissa')->filter->left;

$narrowed->name # -> 'title'

# AND на уровне целиком строится через filter с двумя парами:
my $two = $qb->filter(title => 'Clarissa', author => 7);
$two->filter->op # -> 'AND'
```

## or_filter (@expr)

Добавляет условие через `OR`.

## annotate (@select)

Добавляет поля в выборку. Поле без `Expr` превращается в `Field` главной сущности.

```perl
package Storage::Book::Annotate {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

# Алиас берёт первые буквы сегментов через _: "Storage::Book::Annotate" даёт S
$qb->_alias # -> 'S'

my $query = $qb->annotate('title');

scalar(@{$query->select})    # -> 2
$query->select->[1]          # -> 'title'
$query->select->[0]->name    # -> 'title'
$query->select->[0]->alias   # -> 'S'
```

## add_annotate (@select)

Добавляет поля поверх уже отобранных.

## group_by (@groups)

Задаёт `GROUP BY`.

## add_group_by (@groups)

Добавляет выражения в `GROUP BY` поверх уже заданных.

## having (@expr)

Задаёт `HAVING` — фильтр после группировки.

## and_having (@expr)

Дополняет `HAVING` через `AND`.

## or_having (@expr)

Дополняет `HAVING` через `OR`.

## order_by (@orders)

Задаёт `ORDER BY`.

## add_order_by (@orders)

Добавляет сортировку поверх уже заданной.

## limit ($limit)

Задаёт ограничение количества строк.

```perl
package Storage::Book::Limit {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Limit');

my $query = $qb->limit(10);

ref $query     # -> 'Aion::Aya::Query'
$query->limit  # -> 10
```

## offset ($offset)

Задаёт смещение выборки.

## delete ()

Переключает запрос на операцию `DELETE`.

## update (@update)

Переключает запрос на операцию `UPDATE`, переданные поля становятся секцией `SET`.

## insert (@insert)

Переключает запрос на операцию `INSERT`, переданные поля становятся секцией `SET`.

## inner_join ($alias, $field)

Присоединяет сущность внутренним (`INNER`) объединением.

## left_join ($alias, $field)

Присоединяет сущность левым (`LEFT`) объединением.

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
