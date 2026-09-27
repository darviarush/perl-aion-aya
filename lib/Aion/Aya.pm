package Aion::Aya;

use common::sense;

our $VERSION = "0.0.0";

use Aion::Aya::Model;

use Aion -role, -export => [qw/presents primary_key unique_key index_key foreign_key memory_key fetch_key/];

# Информация о таблицах: класс => Aion::Aya::Model
our %META;

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
	my ($fields, @options) = @_;
	$META{caller()}->add_primary_key($fields, +{@options});
	return;
}

# Если ключ - составной
sub unique_key(@) {
	my ($name, $fields, @options) = @_;
	$META{caller()}->add_unique_key($name, $fields, +{@options});
	return;
}

# Если ключ - составной
sub index_key(@) {
	my ($name, $fields, @options) = @_;
	$META{caller()}->add_index_key($name, $fields, +{@options});
	return;
}

# Если ключ - составной
sub foreign_key(@) {
	my ($name, $to_class, $fields, $to_fields, @options) = @_;
	$META{caller()}->add_foreign_key($name, $to_class, $fields, $to_fields, +{@options});
	return;
}

# Часть строки с указанными полями будет хранится в таком ключе.
# Укажите в имени методы в фигурных скобках по которым название ключа для кеша будет сформировано. Например: "{*}-{id}", где {*} - название таблицы, а {id} - значение идентификатора.
# Экранируйте обратным слешем фигурные скобки, если они нужны в названии ключа.
# Когда запрашивается поле из entity и его там нет, то оно подгружается из кеша по ключу в который входит. Заодно подгружаются и все другие поля в этом ключе.
# Если же поле не входит ни в один memory_key или fetch_key, то оно будет загружатся из базы в гордом одиночестве, что может понадобится для блобов и других объёмных полей
sub memory_key(@) {
	my ($key_format, $fields, @options) = @_;
	$META{caller()}->add_memory_key($key_format, $fields, +{@options});
	return;
}

# Когда поле будет запрошено из Entity, то оно загрузится вместе с другими полями в ключе, если эти поля отсутствуют в объекте
sub fetch_key(@) {
	my ($fields) = @_;
	$META{caller()}->add_fetch_key($fields);
	return;
}

#@category Аспекты

# Объявляет первичный ключ таблицы
aspect pk => sub {
	my ($value, $feature) = @_;
	my $cls = $feature->{cls};

	my $col = $Aion::META{$cls}{aspect}{col};
	$col->($value, $feature);
	
	$META{$cls}->add_primary_key([$feature->{name}]);
};

# Определяет генератор для создания идентификаторов
aspect next => sub {
	my ($value, $feature) = @_;
	my $cls = $feature->{cls};
	$META{$cls}->next($value);
};

my $Column = Dict([List::Util::pairmap { ($a => Option[$b]) } %Aion::Aya::Table::COLUMN]);

# Объявляет поле таблицы
aspect col => sub {
	my ($value, $feature) = @_;

	Aion::Aya::Model->make_column_feature($feature);

	my $cls = $feature->{cls};
	my $model = $META{$cls};
	my $name = $feature->{name};

	$value = {} if $value eq 1;
	
	$value->{order} //= 1+keys %{$model->{column}};
	$Column->validate($value, "$name/col");

	my $col_name = $value->{name} // $name;

	my $field = {
		name => $name,
		type => 'col',
		col_name => $col_name,
	};

	Aion::Aya::Model->Field->validate($field, "$name/col/field");
	$model->{field}{$name} = $field;
};

# Объявляет прямую ссылку на другую таблицу
aspect ref => sub {
	my ($value, $feature) = @_;

	Aion::Aya::Model->make_column_feature($feature);

	my $cls = $feature->{cls};
	my $model = $META{$cls};
	my $name = $feature->{name};

	Dict([
		ref_field => Option[Str],
		bk_field => Option[Str],
		col => Option[$Column],
	])->validate($value, "$name/ref") if ref $value;
	
	my $ref_field = ref $value? $value->{ref_field} // 'id': 'id';

	my $bk_field = $value eq 1? undef: ref $value? $value->{bk_field}: $value =~ s/^-//;
	
	my $col = ref $value? $value->{col} // {}: {};
	$col->{order} //= 1+keys %{$model->{column}};

	my $col_name = $value->{name} // "$name\_id";
	my $ref = Aion::Aya::Model->get_ref($feature);

	my $field = {
		name => $name,
		type => 'ref',
		col_name => $col_name,
		ref => [$ref, $ref_field, $bk_field],
	};

	Aion::Aya::Model->Field->validate($field, "$name/ref/field");
	$model->{field}{$name} = $field;
};

# Объявляет обратную ссылку с другой таблицы или связи многие-ко-многим
aspect bk => sub {
	my ($value, $feature) = @_;

	Aion::Aya::Model->make_column_feature($feature);

	my $cls = $feature->{cls};
	my $model = $META{$cls};
	my $name = $feature->{name};

	my $ref = Aion::Aya::Model->get_ref($feature);
	my $ref_field = $value =~ s/^-//r;

	my $field = {
		name => $name,
		type => 'bk',
		ref => [$ref, $ref_field, undef],
	};

	Aion::Aya::Model->Field->validate($field, "$name/bk/field");
	$model->{field}{$name} = $field;
};

# Объявляет связь многие-ко-многим на другую таблицу
# has x => (is => 'ro', isa => 'RefClass', m2m => 1);
# has x => (is => 'ro', isa => 'RefClass', m2m => -bk_field);
# has x => (is => 'ro', isa => 'RefClass', m2m => {
# 	table => 'table_name', # если не указана - имена таблиц через 2 с постфиксом _m2m
#   options => [table_options],
#   ref_field => '', # если не указан - id
#   bk_field => '', # если не указан - id
# });
aspect m2m => sub {
	my ($value, $feature) = @_;

	Aion::Aya::Model->make_column_feature($feature);

	my $cls = $feature->{cls};
	my $model = $META{$cls};
	my $name = $feature->{name};

	Dict([
		table => Option[Str],
		options => Option[Any],
		ref_field => Option[Str],
		bk_field => Option[Str],
	])->validate($value, "$name/m2m") if ref $value;

	my $ref_cls = Aion::Aya::Model->get_ref($feature);
	my $ref_model = Aion::Aya::Model->get($ref_cls);

	my $ref_field = ref $value? $value->{ref_field} // 'id': 'id';
	my $bk_field = $value eq 1? undef: ref $value? $value->{bk_field}: $value =~ s/^-//;

	# Промежуточная таблица: имя можно задать, иначе — имена таблиц через "2" с постфиксом _m2m
	my $table = ref $value? $value->{table}: undef;
	$table //= join('2', $model->{table}, $ref_model->{table}) . '_m2m';

	my $m2m_table = Aion::Aya::Table->new(
		table => $table,
		options => ref $value? $value->{options}: undef,
	);

	my $field = {
		name => $name,
		type => 'm2m',
		ref => [$ref_cls, $ref_field, $bk_field],
		table => $m2m_table,
	};

	Aion::Aya::Model->Field->validate($field, "$name/m2m/field");
	$model->{field}{$name} = $field;
};

#@category Аспекты для индексов

# Делает поле уникальным
aspect unique => sub {
	my ($value, $feature) = @_;

	my $name = $value eq 1
		? $META{$feature->{cls}}->col_name($feature->{name}) . '_unx'
		: $value =~ s/^-//r;

	my $cls = $feature->{cls};
	$META{$cls}->add_unique_key($name, [$feature->{name}]);
};

# Добавляет поисковый индекс на поле
aspect index => sub {
	my ($value, $feature) = @_;

	my $name = $value eq 1
		? $META{$feature->{cls}}->col_name($feature->{name}) . '_idx'
		: $value =~ s/^-//r;
	
	my $cls = $feature->{cls};
	$META{$cls}->add_index_key($name, [$feature->{name}]);
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
		m2m => {table => -co_authors_books, ref => -cobooks});
	
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
