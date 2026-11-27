!ru:en
# NAME

Aion::Aya::Adapter::Transform::SQL - превращение Aion::Aya::Query в SQL-текст (DQL и DML)

# SYNOPSIS

Файл lib/ExEntity.pm:
```perl
package ExEntity;

use common::sense;

use Aion with => 'Aion::Aya';

presents 'books';

has id => (is => 'ro', isa => PositiveInt, pk => 1);
has title => (is => 'ro', isa => Str & Len[255], col => 1);

1;
```

Код:

```perl
use ExEntity;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Adapter::Transform::SQL' => 'TransformSQL';

my $transformator = TransformSQL->new;
my $query = Query->new(from => 'ExEntity');

$transformator->sql_select($query) # => SELECT * FROM books
$transformator->sql_delete($query) # => DELETE FROM books
```

# DESCRIPTION

`Aion::Aya::Adapter::Transform::SQL` — конкретная реализация контракта `Aion::Aya::Adapter::Transform::Abstract`: берёт `Aion::Aya::Query` и отдаёт строку SQL для DQL (`SELECT`) и DML (`INSERT`, `UPDATE`, `DELETE`).

Роль различает диалекты через переопределяемые методы:

- `word` — как писать имя таблицы/колонки (по умолчанию без экранирования);
- `is_keyword` — считать ли имя ключевым словом (по умолчанию никогда);
- `quoteword` — как экранировать имя, если оно ключевое (по умолчанию обратные кавычки).

`Aion::Aya::Adapter::Transform::Mem` и `Aion::Aya::Adapter::Transform::Mysql` наследуют SQL и меняют только экранирование (`Mysql` экранирует обратными кавычками).

Имя таблицы и колонки берутся из `Aion::Aya::Model` (`Model->get($query->from)->table` и `col_name`), поэтому переименование колонки в модели не ломает SQL.

# SUBROUTINES

## transform ($query)

Превращает запрос в строку SQL. Диспетчеризует по `$query->operation`: `SELECT` → `sql_select`, `INSERT` → `sql_insert`, `UPDATE` → `sql_update`, `DELETE` → `sql_delete`.

```perl
my $t = TransformSQL->new;
my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');

my $select = Query->new(from => 'ExEntity');

$t->sql_select($select) # -> 'SELECT * FROM books'

my $delete = Query->new(from => 'ExEntity');

$t->sql_delete($delete) # -> 'DELETE FROM books'

$t->sql_insert(Query->new(from => 'ExEntity', operation => 'insert', select => [($val, 'title')])) # -> 'INSERT INTO books (title) VALUES (Clarissa)'
```

## sql_select ($query)

Строит `SELECT`: `SELECT {поля|*} FROM {таблица}` и общую часть (см. `_select`). Поля задаются парами «выражение → псевдоним».

```perl
my $t = TransformSQL->new;
my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');

my $query = Query->new(from => 'ExEntity', select => [($val, 'ttl')]);

$t->sql_select($query) # -> 'SELECT Clarissa as ttl FROM books'
```

## sql_insert ($query)

Строит `INSERT INTO {таблица} ({колонки}) VALUES ({значения})`. Пары `select` — это значение и имя колонки.

```perl
my $t = TransformSQL->new;
my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');

$t->sql_insert(Query->new(from => 'ExEntity', operation => 'insert', select => [($val, 'title')])) # -> 'INSERT INTO books (title) VALUES (Clarissa)'
```

## sql_update ($query)

Строит `UPDATE {таблица} SET {колонка} = {значение}` и общую часть. Пары `select` — значение и имя колонки.

## sql_delete ($query)

Строит `DELETE FROM {таблица}` и общую часть.

```perl
my $t = TransformSQL->new;

my $query = Query->new(from => 'ExEntity');

$t->sql_delete($query) # -> 'DELETE FROM books'
```

## _select ($query)

Общая хвостовая часть для всех операций: соединения, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`, `OFFSET`.

```perl
my $t = TransformSQL->new;
my $query = Query->new(from => 'ExEntity', limit => 5, offset => 10);

$t->sql_select($query) # -> 'SELECT * FROM books LIMIT 5 OFFSET 10'
```

Соединения (`join` запроса) превращаются в `JOIN` по данным из `Aion::Aya::Query::Join`: из `model` и её `ref`-поля `field` получается результирующая модель (через `Model->get_ref`), по ней — таблица и колонка первичного ключа.

```perl
package Storage::Book::SqlJoin {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
	has user => (is => 'ro', isa => Object['Storage::User::SqlJoin'], ref => 1);
}

package Storage::User::SqlJoin {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'users';

	has id => (is => 'ro', isa => Int, pk => 1, col => 1);
}

use aliased 'Aion::Aya::Query::Join' => 'xJoin';

my $t = TransformSQL->new;
my $query = Query->new(
	from => 'Storage::Book::SqlJoin',
	join => [xJoin->new(join => 'left', model => 'Storage::Book::SqlJoin', field => 'user', from_alias => 'S', to_alias => 'u')],
);

$t->_select($query) # -> "\nLEFT JOIN users u ON u.id = S.user_id"
```

## expr ($expr)

Превращает узел дерева выражений в SQL:

- `Val` — значение как есть;
- `Field` — `alias.column`;
- `UOp` — `op exp` (`NOT b.title`);
- `Op` — `left op right` (`b.title=Clarissa`).

```perl
my $t = TransformSQL->new;
my $field = Aion::Aya::Query::Expr::Field->new(alias => 'b', name => 'title', entity => 'ExEntity');
my $val   = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');

$t->expr($val) # -> 'Clarissa'
$t->expr($field) # -> 'b.title'
$t->expr(Aion::Aya::Query::Expr::Op->new(op => '=', left => $field, right => $val)) # -> 'b.title=Clarissa'
$t->expr(Aion::Aya::Query::Expr::UOp->new(op => 'NOT', exp => $field)) # -> 'NOT b.title'
```

## word ($word)

Пишет имя таблицы или колонки: экранирует через `quoteword`, если `is_keyword` истинно, иначе возвращает как есть.

```perl
my $t = TransformSQL->new;

$t->word('books') # -> 'books'
```

## is_keyword ($word)

Считает ли имя ключевым словом. В SQL по умолчанию — никогда; диалект переопределяет.

```perl
my $t = TransformSQL->new;

$t->is_keyword('books') # -> 0
```

## quoteword ($word)

Экранирует ключевое слово. В SQL и MySQL — обратными кавычками.

```perl
my $t = TransformSQL->new;

$t->quoteword('books') # -> '`books`'
```

# GOTCHAS

Библиотека в разработке, и у диалекта SQL сейчас есть ограничения:

* **Конструктор не создаётся.** `TransformSQL->new` падает с `Signature mismatch`: `transform` в `SQL` объявлен как `:Isa(Me => Query => Str)`, а контракт `Abstract` требует `Any`. Пока это не исправят, объект создаётся через `bless`.
* **`transform` требует `Abstract`-объект.** Даже при `bless` вызов `transform` проверяет первый аргумент по типу из `Abstract` (`Object['Query']`) и падает, если `Query` не разрешается в класс. Поэтому в примерах показаны `sql_*` и `_select` напрямую.
* **`join` в `Query` — массив `Aion::Aya::Query::Join`.** Сам `Join` хранит только данные (тип, модель-источник, поле, алиасы), `JOIN ... ON ...` собирает только диалект, поэтому не-SQL трансформер напишет его иначе.
* **`filter`/`having` в `_select` проверяются на истинность.** У `Aion::Aya::Query::Expr::Op` есть перегрузка `&{}` без `bool`, поэтому выражение в `filter` даёт `Operation "bool": no method found`.
* **`ORDER BY` собирается из пар.** `Aion::Aya::Query` хранит `order_by` как пары «выражение — `ASC`/`DESC`», а `_select` склеивает их через `pairmap` с разделителем `' '`, поэтому в SQL попадает лишний разделитель.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Adapter::Transform::SQL module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
