!ru:en
# NAME

Aion::Aya::Adapter::Diff::MemDiff - сравнение моделей со структурой DBD::Mem и генерация DDL

# SYNOPSIS

Файл lib/DiffExample.pm:
```perl
package DiffExample;
use common::sense;

use Aion;
use Aion::Aya::Table;
use Aion::Aya::Adapter::Diff::MemDiff;
use Aion::Aya::Adapter::Transform::SQL;

# MemDiff берёт экранирование у transformator адаптера, поэтому нужен adapter
package DiffAdapter {
	use Aion;
	with 'Aion::Aya::Adapter';

	has adapter => (is => 'ro', isa => 'Aion::Aya::Adapter', default => sub { undef });
	has transformator => (is => 'ro', isa => 'Aion::Aya::Adapter::Transform::Abstract', default => sub { Aion::Aya::Adapter::Transform::SQL->new });
	sub iterator :Isa(Me => Object['Aion::Aya::Query'] => Object['Aion::Aya::Iterator']) { }
	sub execute :Isa(Me => Object['Aion::Aya::Query'] => PositiveInt) { }
	sub next_val :Isa(Me => Object['Aion::Aya'] => Str) { }
	sub next :Isa(Me => Hashref => Any) { }
}

package DiffExample;
our $diff = bless { adapter => DiffAdapter->new }, 'Aion::Aya::Adapter::Diff::MemDiff';

our $book = Aion::Aya::Table->new(
	table => 'book',
	primary_key => {columns => ['id'], options => []},
	columns => [
		{name => 'id', type => 'int', is_nullable => 0, default => '', options => '', comment => '', order => 0},
		{name => 'title', type => 'varchar(255)', is_nullable => 0, default => '', options => '', comment => '', order => 1},
	],
);

1;
```

```perl
use DiffExample;

my $ddl = $DiffExample::diff->diff({book => $DiffExample::book}, {});

ref $ddl  # -> 'ARRAY'
scalar @$ddl # -> 1
$ddl->[0] =~ /^CREATE TABLE book/ # -> 1
```

# DESCRIPTION

`MemDiff` — реализация `Aion::Aya::Adapter::Diff::Abstract` для in-memory базы на `DBD::Mem`. Модуль умеет две вещи:

- **сравнивать** набор моделей с набором таблиц базы (`diff`) и возвращать DDL, приводящий базу к моделям;
- **строить текст DDL** по описанию таблицы (`Aion::Aya::Table`): `CREATE TABLE`, `DROP TABLE`, `ALTER TABLE`, столбцы, ключи, внешние ключи.

`Aion::Aya::Adapter::Diff::MysqlDiff` наследует `MemDiff` и меняет только `model2table` (добавляет комментарии из аннотаций).

DDL-методы собирают текст, а имена экранируются через `word`, который делегирует `adapter->transformator->word`. Поэтому `MemDiff` держат рядом с `adapter`.

# FEATURES

## adapter

Адаптер, у которого берутся соединение (`connect`/`finish`), трансформер (`word`) и метаданные. Наследуется от `Abstract`.

# SUBROUTINES

## diff ($models, $database)

Сравнивает два хеша «имя таблицы => `Aion::Aya::Table`»: модели и текущую структуру базы. Возвращает ссылку на массив DDL:

- таблица есть в моделях, но нет в базе → `CREATE TABLE`;
- таблица есть в базе, но нет в моделях → `DROP TABLE`;
- одинаковые таблицы → ничего.

Изменения внутри существующих таблиц (ALTER) пока не вычисляются.

```perl
use DiffExample;

my $ddl = $DiffExample::diff->diff({book => $DiffExample::book}, {});

scalar @$ddl # -> 1
$ddl->[0] =~ /^CREATE TABLE book/ # -> 1

# Одинаковые структуры — пустой список
my $same = $DiffExample::diff->diff({book => $DiffExample::book}, {book => $DiffExample::book});

scalar @$same # -> 0
```

## model2table ($model)

Строит `Aion::Aya::Table` из модели (`Aion::Aya::Model`): перебирает `col`-поля по `order`, берёт типы через `isa2type`, учитывает `Maybe` (nullable) и первичный ключ. У `MemDiff` нет комментариев и опций, потому что `DBD::Mem` их не поддерживает.

```perl
use DiffExample;

ref $DiffExample::diff->can('model2table') # -> 'CODE'
```

## structure ()

Читает структуру таблиц из `DBD::Mem` (`table_info`/`column_info`) и возвращает хеш «имя => `Aion::Aya::Table`». Требует работающего `adapter->connect`.

## isa2type ($isa)

Преобразует тип Aion в имя SQL-типа. Для `DBD::Mem` поддерживаются `Int`, `TinyInt`, `LongInt` (`int`/`tinyint`/`int`); неизвестный тип — исключение `Not convert isa … to type!`.

```perl
use DiffExample;
use Aion::Aya::Types;

$DiffExample::diff->isa2type(Int())     # -> 'int'
$DiffExample::diff->isa2type(TinyInt()) # -> 'tinyint'
$DiffExample::diff->isa2type(LongInt()) # -> 'int'
```

## get_tables ()

Возвращает имена таблиц базы через `table_info`. Используется в `structure`.

## get_columns ($table)

Возвращает описание столбцов таблицы через `column_info`: `name`, `type`, `is_nullable`, `default` (из `SQL::Statement`), `order`. `options`/`comment` всегда пусты.

## get_indexes ($table)

Заготовка: читает первичный ключ через `primary_key_info` и статистику через `statistics_info`, но индексы пока не возвращает.

## word ($word)

Экранирование имени таблицы/колонки: делегирует `adapter->transformator->word`.

## show_create_table ($table)

`CREATE TABLE {таблица} (\n{столбцы, первичный ключ, индексы, внешние ключи}\n)`.

```perl
use DiffExample;

my $sql = $DiffExample::diff->show_create_table($DiffExample::book);

$sql =~ /^CREATE TABLE book \(/ # -> 1
$sql =~ /PRIMARY KEY \(id\)/     # -> 1
```

## show_drop_table ($table)

`DROP TABLE {таблица}`.

```perl
use DiffExample;

$DiffExample::diff->show_drop_table($DiffExample::book) # -> 'DROP TABLE book'
```

## show_rename_table ($table, $to)

`ALTER TABLE {таблица} RENAME TO {новое имя}`.

```perl
use DiffExample;

$DiffExample::diff->show_rename_table($DiffExample::book, 'book2') # -> 'ALTER TABLE book RENAME TO book2'
```

## show_truncate_table ($table)

Очищает таблицу: `DELETE FROM {таблица}`.

```perl
use DiffExample;

$DiffExample::diff->show_truncate_table($DiffExample::book) # -> 'DELETE FROM book'
```

## show_modify_table ($table)

`ALTER TABLE {таблица} ` + опции таблицы. В `DBD::Mem` опций нет (`show_definition_table` возвращает пустую строку), поэтому получается `ALTER TABLE book `.

```perl
use DiffExample;

$DiffExample::diff->show_modify_table($DiffExample::book) # -> 'ALTER TABLE book '
```

## show_create_definition ($table)

Внутренности `CREATE TABLE`: столбцы, `PRIMARY KEY`, индексы (`unique_keys`, `index_keys`), внешние ключи, соединённые через `,\n`.

```perl
use DiffExample;

my $t = Aion::Aya::Table->new(
	table => 'book',
	primary_key => {columns => ['id'], options => []},
	columns => [{name => 'id', type => 'int', is_nullable => 0, default => '', options => '', comment => '', order => 0}],
	index_keys => [{name => 'idx_book', columns => ['title'], options => []}],
);

$DiffExample::diff->show_create_definition($t) =~ /PRIMARY KEY \(id\),\nKEY idx_book \(title\)/ # -> 1
```

## show_definition_table ($table, $create)

Опции таблицы. В `MemDiff` всегда пустая строка; наследники могут переопределить.

## show_column ($col)

Столбец с именем: `{имя} {тип [NOT NULL] [DEFAULT …] [опции]}`.

```perl
use DiffExample;

$DiffExample::diff->show_column({name => 'id', type => 'int', is_nullable => 0}) # -> 'id int NOT NULL'
```

## show_definition_column ($col, $with_keys)

Определение столбца без имени: тип (по умолчанию `TEXT`), `NOT NULL`, `DEFAULT`, опции.

```perl
use DiffExample;

$DiffExample::diff->show_definition_column({type => 'int', is_nullable => 0, default => 7}) # -> 'int NOT NULL DEFAULT 7'
```

## show_index ($index)

Индекс с именем: `KEY {имя} ({колонки})`.

```perl
use DiffExample;

$DiffExample::diff->show_index({name => 'idx_book', columns => ['title']}) # -> 'KEY idx_book (title)'
```

## show_definition_index ($index)

Индекс без имени: `({колонки})`.

## show_foreign ($fk)

Внешний ключ с именем: `CONSTRAINT {имя} FOREIGN KEY ({колонки}) REFERENCES {таблица} ({колонки})`.

```perl
use DiffExample;

$DiffExample::diff->show_foreign({name => 'fk_book_author', to_table => 'author', columns => ['author_id'], to_columns => ['id']}) # -> 'CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES author (id)'
```

## show_definition_foreign ($fk)

Внешний ключ без имени: `FOREIGN KEY (...) REFERENCES ... (...)`.

## show_create_database / show_drop_database / show_modify_database / show_definition_database

DDL для базы (`CREATE DATABASE`, `DROP DATABASE`, `ALTER DATABASE`). `show_definition_database` отдаёт пары `DEFAULT CHARACTER SET`/`DEFAULT COLLATE`, если у объекта есть `charset`/`collation`.

# GOTCHAS

* **`MemDiff->new` падает.** `model2table` в `MemDiff` объявлен как `:Isa(Me => Model => Table)`, а контракт `Abstract` — как `:Isa(Me => Model => Table)` с типом `Aion::Aya::Model`; сигнатуры не совпадают (`Signature mismatch`). Плюс `Model` в сигнатуре разрешается в несуществующий `Object['Model']`. Поэтому в примерах объект создаётся через `bless`, а `model2table` пока не работает.
* **`adapter` обязателен для `word`.** DDL-методы зовут `word` → `adapter->transformator->word`, поэтому `adapter` нужен даже для чистой генерации текста.
* **`diff` работает только для `Aion::Aya::Table`.** Оба аргумента проверяются как `HashRef[Object['Aion::Aya::Table']]`, поэтому передавать хеши столбцов вместо объектов нельзя.
* **ALTER существующих таблиц не реализован.** `diff` делает только `CREATE`/`DROP`; изменения столбцов/индексов — `TODO`.
* **`structure` требует рабочего соединения.** Он ходит в `adapter->connect` и `DBD::Mem`, поэтому в отрыве от базы не проверяется.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Adapter::Diff::MemDiff module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
