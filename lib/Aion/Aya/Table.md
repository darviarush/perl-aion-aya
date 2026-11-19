# NAME

Aion::Aya::Table - снимок структуры таблицы в базе: столбцы, ключи и внешние связи

# SYNOPSIS

```perl
use Aion::Aya::Table;

my $table = Aion::Aya::Table->new(
	table => 'book',
	primary_key => {columns => ['id'], options => []},
	columns => [
		{name => 'id', type => 'int', is_nullable => 0, default => '', options => 'auto_increment', comment => '', order => 0},
		{name => 'title', type => 'varchar(255)', is_nullable => 0, default => '', options => '', comment => 'Название', order => 1},
	],
	unique_keys => [{name => 'unq_book_title', columns => ['title'], options => []}],
	index_keys => [{name => 'idx_book_title', columns => ['title'], options => []}],
	foreign_keys => [{
		name => 'fk_book_author',
		to_table => 'author',
		columns => ['author_id'],
		to_columns => ['id'],
		options => ['on delete cascade'],
	}],
	options => 'ENGINE=InnoDB',
);

$table->table                          # -> 'book'
$table->primary_key->{columns}->[0]    # -> 'id'
scalar(@{$table->columns})             # -> 2
$table->columns->[1]->{name}           # -> 'title'
$table->columns->[1]->{comment}        # -> 'Название'
$table->unique_keys->[0]->{name}       # -> 'unq_book_title'
$table->index_keys->[0]->{name}        # -> 'idx_book_title'
$table->foreign_keys->[0]->{to_table}  # -> 'author'
$table->foreign_keys->[0]->{options}->[0] # -> 'on delete cascade'
$table->options                        # -> 'ENGINE=InnoDB'
```

Обязательные поля — `table`, `primary_key` и `columns`; их отсутствие даёт исключение:

```perl
use Aion::Aya::Table;

Aion::Aya::Table->new(columns => []) # @-> table required
```

# DESCRIPTION

`Aion::Aya::Table` — общий формат описания структуры таблицы. Один и тот же объект получается двумя путями:

- из модели (`Migration::Comparator->model2table`) — по метаданным `%Aion::Aya::META`;
- из базы (`Migration::Comparator->structure`) — по системным каталогам `DBI`.

`diff` сравнивает два `HashRef[Aion::Aya::Table]` (модель и базу) и возвращает DDL-инструкции, которые приводят базу к модели. Поэтому именно здесь живёт контракт между метаданными, драйвером и миграциями.

# FEATURES

## table

Имя таблицы в базе.

## options

Опции таблицы в базе.

## primary_key

Первичный ключ.

## columns

Столбцы.

## unique_keys

Уникальные ключи.

## index_keys

Индексы.

## foreign_keys

Внешние ключи.

# TYPES

## Column

Столбец таблицы. Все поля обязательны.

- `name` — имя в базе;
- `type` — тип SQL (`int`, `varchar(255)`);
- `is_nullable` — допускает `NULL`;
- `default` — значение по умолчанию;
- `options` — дополнительные опции (`auto_increment`, `unsigned`);
- `comment` — комментарий;
- `order` — порядок в определении.

```perl
my $col = {name => 'id', type => 'int', is_nullable => 0, default => '', options => 'auto_increment', comment => '', order => 0};

$col ~~ Aion::Aya::Table::Column() # -> 1

# Без обязательного поля type
my %no_type = %$col; delete $no_type{type};
\%no_type ~~ Aion::Aya::Table::Column() # -> ''

# Лишнее поле
my %extra = (%$col, extra => 1);
\%extra ~~ Aion::Aya::Table::Column() # -> ''

# Неверный тип поля
my %bad_type = (%$col, is_nullable => 'maybe');
\%bad_type ~~ Aion::Aya::Table::Column() # -> ''
```

## OptionColumn

То же, что `Column`, но все поля необязательны — для чтения из базы, где часть сведений недоступна.

```perl
my $empty = {};
$empty ~~ Aion::Aya::Table::OptionColumn() # -> 1

my $name_only = {name => 'id'};
$name_only ~~ Aion::Aya::Table::OptionColumn() # -> 1

my $name_type = {name => 'id', type => 'int'};
$name_type ~~ Aion::Aya::Table::OptionColumn() # -> 1

# Тип проверяется, если поле задано
my %bad = (is_nullable => 'maybe');
\%bad ~~ Aion::Aya::Table::OptionColumn() # -> ''
```

## PrimaryKey

Первичный ключ. В отличие от `Key`, у него нет имени — в базе первичный ключ один.

- `columns` — список столбцов;
- `options` — опции (`using` и т. п.).

```perl
my $pk = {columns => ['id'], options => []};

$pk ~~ Aion::Aya::Table::PrimaryKey() # -> 1

# Составной первичный ключ
my $composite_pk = {columns => ['author', 'title'], options => []};
$composite_pk ~~ Aion::Aya::Table::PrimaryKey() # -> 1

# Без столбцов
my $no_cols = {options => []};
$no_cols ~~ Aion::Aya::Table::PrimaryKey() # -> ''

# Имени у первичного ключа нет
my $named = {name => 'pk', columns => ['id'], options => []};
$named ~~ Aion::Aya::Table::PrimaryKey() # -> ''
```

## Key

Ключ таблицы: уникальный или обычный индекс.

- `name` — имя ключа;
- `columns` — список столбцов;
- `options` — опции (`using` и т. п.).

```perl
my $key = {name => 'idx_xy', columns => ['pos_history', 'pos_action'], options => []};

$key ~~ Aion::Aya::Table::Key() # -> 1

# Без имени
my %no_name = %$key; delete $no_name{name};
\%no_name ~~ Aion::Aya::Table::Key() # -> ''

# Столбцы — не массив строк
my %not_array = (%$key, columns => 'pos_history');
\%not_array ~~ Aion::Aya::Table::Key() # -> ''


# Составной ключ
my $composite = {name => 'pk', columns => ['author', 'title'], options => []};
$composite ~~ Aion::Aya::Table::Key() # -> 1
```

## ForeignKey

Внешний ключ.

- `name` — имя ограничения;
- `to_table` — таблица назначения;
- `columns` — столбцы текущей таблицы;
- `to_columns` — столбцы таблицы назначения;
- `options` — опции (`on delete cascade`).

```perl
my $fk = {name => 'fk_book_author', to_table => 'author', columns => ['author_id'], to_columns => ['id'], options => ['on delete cascade']};

$fk ~~ Aion::Aya::Table::ForeignKey() # -> 1

# Без таблицы назначения
my %no_table = %$fk; delete $no_table{to_table};
\%no_table ~~ Aion::Aya::Table::ForeignKey() # -> ''

# Таблица назначения должна быть именем пакета
my %bad_table = (%$fk, to_table => 'Author Table');
\%bad_table ~~ Aion::Aya::Table::ForeignKey() # -> ''

# Неверные столбцы
my %bad_cols = (%$fk, to_columns => 'id');
\%bad_cols ~~ Aion::Aya::Table::ForeignKey() # -> ''
```

Все пять типов — `Dict`, то есть проверяются при установке: незаявленный ключ или неверный тип дают исключение.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Table module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
