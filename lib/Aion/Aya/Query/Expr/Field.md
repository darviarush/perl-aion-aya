# NAME

Aion::Aya::Query::Expr::Field - ссылка на столбец таблицы в выражении

# SYNOPSIS

```perl
package Storage::Book {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::Query::Expr::Field;

my $field = Aion::Aya::Query::Expr::Field->new(
	alias => 'b',
	name => 'title',
	entity => 'Storage::Book',
);

$field->alias   # -> 'b'
$field->name    # -> 'title'
$field->entity  # -> 'Storage::Book'
$field->isa('Aion::Aya::Query::Expr') # -> 1
```

# DESCRIPTION

`Field` — лист дерева выражений, который ссылается на столбец сущности. В SQL превращается в `alias.column`.

Поле задаётся тройкой:

- `entity` — класс сущности (по нему `Aion::Aya::Model` находит имя таблицы и столбца);
- `name` — имя фичи сущности (не колонки);
- `alias` — псевдоним таблицы в запросе.

По `entity` и `name` диалект получает настоящее имя столбца через `Model->col_name`, поэтому переименование колонки в модели не ломает запросы.

# FEATURES

## alias

Псевдоним таблицы в запросе (`b` в `b.title`).

## name

Имя фичи сущности (свойства `has`), а не имя столбца.

## entity

Класс сущности, которой принадлежит поле.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query::Expr::Field module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
