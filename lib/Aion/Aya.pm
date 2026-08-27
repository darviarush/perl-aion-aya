package Aion::Aya;

use common::sense;

our $VERSION = "0.0.0";

use Aion::Aya::Model;

use Aion -role;

# Информация о таблицах
our %META;

# Импорт функций в модуль
sub import {
	my (undef, @attrs) = @_;
	my $pkg = caller;

	local $" = " ";
	my $attrs = @attrs? " qw{@attrs}": "";
	eval "use Aion$attrs; with qw/Aion::Aya/; 1" or die;
	
	*{"$pkg\::$_"} = \&$_ for qw/presents primary_key unique_key index_key foreign_key memory_key fetch_key/;
}

sub unimport {
	my (undef, @attrs) = @_;
	my $pkg = caller;

   	local $" = " ";
    my $attrs = @attrs? " qw{@attrs}": "";
	eval "no Aion$attrs; 1" or die;
	
	undef &{"$pkg\::$_"} for qw/box_for/;
}

# Менеджер сущностей
has _appearance => (is => 'ro', isa => Maybe['Aion::Aya::Appearance'], eon => 1);

#@category Таблица

# Информация о таблице
sub presents(@) {
	my ($table) = @_;
	my $pkg = caller;
	$META{$pkg} = Aion::Aya::Model->new(pkg => $pkg, table => $table);
	return;
}

#@category Ключи

# Если ключ - составной
sub primary_key(@) {
	my ($name, $fields, @options) = @_;
	my $meta = $META{caller()};
	die "Primary key is already installed!" if exists $meta->{primary_key};
    $meta->primary_key({name => 'PRIMARY', fields => $fields, options => \@options});
	return;
}

# Если ключ - составной
sub unique_key(@) {
	my ($name, $fields, @options) = @_;
	my $meta = $META{caller()};
	my $key = {name => $name, fields => $fields, options => \@options};
	Aion::Aya::Model->Key->validate($key, "unique_key $name");
	push @{$meta->{unique_keys}}, $key;
}

# Если ключ - составной
sub index_key(@) {
	my ($name, $fields, @options) = @_;
	my $meta = $META{caller()};
	my $key = {name => $name, fields => $fields, options => \@options};
	Aion::Aya::Model->Key->validate($key, "index_key $name");
	push @{$meta->{unique_keys}}, $key;
}

# Если ключ - составной
sub foreign_key(@) {
	my ($name, $to_class, $fields, $to_fields, @options) = @_;
	my $meta = $META{caller()};
	my $key = {name => $name, to_class => $to_class, fields => $fields, to_fields => $to_fields, options => \@options};
	Aion::Aya::Model->ForeignKey->validate($key, "foreign_key $name");
	push @{$meta->{foreign_keys}}, $key;
}

# Часть строки с указанными полями будет хранится в таком ключе.
# Укажите в имени методы в фигурных скобках по которым название ключа для кеша будет сформировано. Например: "{*}-{id}", где {*} - название таблицы, а {id} - значение идентификатора.
# Экранируйте обратным слешем фигурные скобки, если они нужны в названии ключа.
# Когда запрашивается поле из entity и его там нет, то оно подгружается из кеша по ключу в который входит. Заодно подгружаются и все другие поля в этом ключе.
# Если же поле не входит ни в один memory_key или fetch_key, то оно будет загружатся из базы в гордом одиночестве, что может понадобится для блобов и других объёмных полей
sub memory_key(@) {
	my ($name_format, $fields, @options) = @_;
	my $meta = $META{caller()};
	my $key = {name => $name_format, fields => $fields, options => \@options};
	Aion::Aya::Model->Key->validate($key, "memory_key $name_format");
	for my $field (@$fields) {
		die "$name_format and $meta->{memory_key}{$_}{name} memory_keys use one field $field!" if exists $meta->{memory_key}{$_};
		$meta->{memory_key}{$_} = $key;
	}
}

# Когда поле будет запрошено из Entity, то оно загрузится вместе с другими полями в ключе, если эти поля отсутствуют в объекте
sub fetch_key(@) {
	my ($fields, @options) = @_;
	my $meta = $META{caller()};
	my $name = join "-", @$fields;
	my $key = {name => $name, fields => $fields, options => \@options};
	Aion::Aya::Model->Key->validate($key, "fetch_key $name");
	for my $field (@$fields) {
		die "$name and $meta->{fetch_key}{$_}{name} fetch_keys use one field $field!" if exists $meta->{fetch_key}{$_};
		$meta->{fetch_key}{$_} = $key;
	}
}

#@category Аспекты

# Объявляет первичный ключ таблицы
aspect pk => sub {
	my ($value, $feature) = @_;
	primary_key([$feature->name]);
};

# Определяет генератор для создания идентификаторов
aspect next => sub {
	my ($value, $feature) = @_;
	my $cls = $feature->{cls};
	$META{$cls}->next($value);
};

my $make_column_feature = sub {
	my ($feature) = @_;
	my $name = $feature->{name};
	$feature->construct
		->add_access("\$self->_appearance->fetch(\$self, '$name') unless exists \$self->{$name};")
		->add_trigger("\$self->_appearance->store(\$self, '$name')")
		->add_cleaner("\$self->_appearance->clear(\$self, '$name')")
	;
};

# Объявляет поле таблицы
aspect col => sub {
	my ($value, $feature) = @_;
	$make_column_feature->($feature);
};

# Объявляет прямую ссылку на другую таблицу
aspect ref => sub {
	my ($value, $feature) = @_;
	$make_column_feature->($feature);
};

# Объявляет обратную ссылку с другой таблицы или связи многие-ко-многим
aspect bk => sub {
	my ($value, $feature) = @_;
	$make_column_feature->($feature);
};

# Объявляет связь многие-ко-многим на другую таблицу
aspect m2n => sub {
	my ($value, $feature) = @_;
	$make_column_feature->($feature);
};

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya - ORM

=head1 VERSION

0.0.0

=head1 SYNOPSIS

Файл .env:

	AION_AYA_CLIENT = Aion::Aya::Client::Memory

Файл lib/Liberia/Storage/Author/Author.pm:

	package Liberia::Storage::Author::Author;
	use common::sense;
	use aliased 'Liberia::Storage::Book::Book';
	
	use Aion;
	
	with 'Aion::Aya';
	
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

Файл lib/Liberia/Storage/Book/Book.pm:

	package Liberia::Storage::Book::Book;
	use common::sense;
	use aliased 'Liberia::Storage::Author::Author';
	
	use Aion;
	
	with 'Aion::Aya';
	
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

Файл lib/Liberia/Storage/Book/BookBox.pm:

	package Liberia::Storage::Book::BookBox;
	use common::sense;
	use aliased 'Liberia::Storage::Book::Book';
	
	use Aion;
	
	with 'Aion::Aya::Box';
	
	box_for Book;
	
	sub all {
		my ($self) = @_;
	
		@{$self->query_builder}
	}
	
	sub get_title_on_P {
		my ($self) = @_;
	
		$self->query_builder
			->join(author => 'a')
			->filter(F"a.name" =~ 'P%' | F"a.name" =~ qr/^P/)
			->scalar(-title);
	}
	
	1;

Файл lib/Liberia/Action/BookAction.pm:

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

Код:

	use common::sense;
	
	use aliased 'Liberia::Action::BookAction';
	
	my $book_action = BookAction->new;
	$book_action->create;
	scalar $book_action->list # -> 1
	$book_action->title # => On the edge of Enchanted Wood, a green oak stands

=head1 DESCRIPTION

C<Aion::Aya> — это ORM который реализует паттерны B<Единица работы> и B<Шлюз к данным таблицы>.

ORM использует идеи C<Doctrine> и C<Hibernate> через B<Менеджер сущностей> и .

=over

=item 1. B<Identity Map> (Карта идентичности)
I<Суть:> Кэш первого уровня.
I<Зачем:> Гарантирует, что каждый объект загружается из базы данных только один раз за транзакцию. Повторный запрос вернет ту же самую ссылку на объект в памяти.

=item 2. B<Lazy Load> (Отложенная загрузка)
I<Суть:> Загрузка связанных данных (например, комментариев к статье) только в момент обращения к ним.
I<Реализация:> Используются Proxy-объекты (заглушки), которые перехватывают обращение к свойствам и делают запрос в БД.

=item 3. B<Foreign Key Mapping> (Отображение внешнего ключа)
I<Суть:> Превращение связей между таблицами (внешних ключей) в объектные связи (коллекции или ссылки на другие объекты).
I<Примеры:> Связи многие-к-одному, один-ко-многим, многие-ко-многим.

=item 4. B<Metadata Mapping> (Отображение метаданных)
I<Суть:> Вынесение правил соответствия полей классов и колонок таблиц в отдельное место.
I<Реализация:> Настройки через атрибуты/аннотации в коде, XML-файлы или YAML-конфигурации.

=item 5. B<Identity Field> (Поле идентичности)
I<Суть:> Обязательное наличие у каждого сохраняемого объекта уникального идентификатора (первичного ключа), который связывает объект в памяти со строкой в таблице.

=back

=head1 SUBROUTINES

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
