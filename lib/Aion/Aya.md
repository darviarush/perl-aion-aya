# NAME

Aion::Aya - ORM

# VERSION

0.0.0

# SYNOPSIS

Файл .env:
```text
AION_AYA_CLIENT = Aion::Aya::Client::Memory
```

Файл lib/Liberia/Storage/Author/Author.pm:
```perl
package Liberia::Storage::Author::Author;
use common::sense;
use aliased 'Liberia::Storage::Book::Book';

use Aion::Aya;

# Authors of the Liberia
presents 'authors';

# The identifier
has id => (is => 'ro', isa => Nat, pk => 1, next => -auto_increment);

# Name of the author
has name => (is => 'ro', isa => NonEmptyStr, col => 1, unique => 1);

# Gender of the author
has gender => (is => 'ro', isa => Enum['male', 'female'], col => 1, index => 1);

# Books who written the author
has books => (is => 'ro', isa => ArrayRef[Book], bk => -author);

# Books written in collaboration
has cobooks => (is => 'ro', isa => ArrayRef[Book], bk => -coauthors);

1;
```

Файл lib/Liberia/Storage/Book/Book.pm:
```perl
package Liberia::Storage::Book::Book;
use common::sense;
use aliased 'Liberia::Storage::Author::Author';

use Aion::Aya;

# Books of the Liberia
presents 'books';

# The identifier
has id => (is => 'ro', isa => Nat, pk => 1, next => -auto_increment);

# Name of a book
has title => (is => 'rw', isa => NonEmptyStr, col => 1, unique => 1);

# Author who written a book
has author => (is => 'rw', isa => Author, ref => -books);

# Co-authors who written a book with an author
has coauthors => (
	is => 'rw',
	isa => ArrayRef[Author],
	m2n => {table => -co_authors_books, ref => -cobooks});

1;
```

Файл lib/Liberia/Storage/Book/BookBox.pm:
```perl
package Liberia::Storage::Book::BookBox;
use common::sense;
use aliased 'Liberia::Storage::Book::Book';

use Aion::Aya::Box;

box_for Book;

sub all {
	my ($self) = @_;

	$self->query_builder->iter_or_array;
}

sub get_title_on_P {
	my ($self) = @_;

	$self->query_builder
		->left_join(author => -a)
		->filter(a__name__like => 'P%')
		->scalar(-title);
}

1;
```

Файл lib/Liberia/Action/BookAction.pm:
```perl
package Liberia::Action::BookAction;
use common::sense;
use aliased 'Liberia::Storage::Author::Author';
use aliased 'Liberia::Storage::Book::Book';
use aliased 'Liberia::Storage::Book::BookBox';

use Aion;

# Entity manager
has appearance => (is => 'ro', isa => 'Aion::Aya::Appearance', eon => 1);

# Book repository
has book_box => (is => 'ro', isa => BookBox, eon => 1);

#@method POST /v1/books
sub create {
	my ($self) = @_;

	my $author = Author->new(name => 'Pushkin A.S.');
	my $book = Book
		->new(title => 'On the edge of Enchanted Wood, a green oak stands')
		->author($author);

	$self->appearance->persist($author, $book)->flush;
}

#@method GET /v1/books
sub list {
	my ($self) = @_;

	map +{
		id => $_->id,
		title => $_->title,
	}, $self->book_box->all;
}

#@method GET /v1/books/title
sub title {
	my ($self) = @_;

	$self->book_box->get_title_on_P;
}

1;
```

Код:
```perl
use common::sense;

use aliased 'Liberia::Action::BookAction';

my $book_action = BookAction->new;
$book_action->create;
scalar $book_action->list # -> 1
$book_action->title # => On the edge of Enchanted Wood, a green oak stands
```

# DESCRIPTION

`Aion::Aya` — это ORM который реализует паттерны **Единица работы** и **Шлюз к данным таблицы**.

ORM использует идеи `Doctrine` и `Hibernate`.

1. **Identity Map** (Карта идентичности)
   *Суть:* Кэш первого уровня.
   *Зачем:* Гарантирует, что каждый объект загружается из базы данных только один раз за транзакцию. Повторный запрос вернет ту же самую ссылку на объект в памяти.
2. **Lazy Load** (Отложенная загрузка)
   *Суть:* Загрузка связанных данных (например, комментариев к статье) только в момент обращения к ним.
   *Реализация:* Используются Proxy-объекты (заглушки), которые перехватывают обращение к свойствам и делают запрос в БД.
3. **Foreign Key Mapping** (Отображение внешнего ключа)
   *Суть:* Превращение связей между таблицами (внешних ключей) в объектные связи (коллекции или ссылки на другие объекты).
   *Примеры:* Связи многие-к-одному, один-ко-многим, многие-ко-многим.
4. **Metadata Mapping** (Отображение метаданных)
   *Суть:* Вынесение правил соответствия полей классов и колонок таблиц в отдельное место.
   *Реализация:* Настройки через атрибуты/аннотации в коде, XML-файлы или YAML-конфигурации.
5. **Identity Field** (Поле идентичности)
   *Суть:* Обязательное наличие у каждого сохраняемого объекта уникального идентификатора (первичного ключа), который связывает объект в памяти со строкой в таблице.

# SUBROUTINES

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
