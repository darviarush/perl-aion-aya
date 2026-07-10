use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Aya - ORM
# 
# # VERSION
# 
# 0.0.0
# 
# # SYNOPSIS
# 
# Файл .env:
#@> .env
#>> AION_AYA_CLIENT = Aion::Aya::Client::Memory
#@< EOF
# 
# Файл lib/Liberia/Storage/Author/Author.pm:
#@> lib/Liberia/Storage/Author/Author.pm
#>> package Liberia::Storage::Author::Author;
#>> use common::sense;
#>> use aliased 'Liberia::Storage::Book::Book';
#>> 
#>> use Aion;
#>> 
#>> with 'Aion::Aya';
#>> 
#>> # Authors of the Liberia
#>> presents 'authors';
#>> 
#>> # The identifier
#>> has id => (is => 'ro', isa => Nat, pk => 1, next => -auto_increment);
#>> 
#>> # Name of the author
#>> has name => (is => 'ro', isa => NonEmptyStr, col => 1, unique => 1);
#>> 
#>> # Gender of the author
#>> has gender => (is => 'ro', isa => Enum['male', 'female'], col => 1, index => 1);
#>> 
#>> # Books who written the author
#>> has books => (is => 'ro', isa => ArrayRef[Book], bk => -author);
#>> 
#>> # Books written in collaboration
#>> has cobooks => (is => 'ro', isa => ArrayRef[Book], bk => -coauthors);
#>> 
#>> 1;
#@< EOF
# 
# Файл lib/Liberia/Storage/Book/Book.pm:
#@> lib/Liberia/Storage/Book/Book.pm
#>> package Liberia::Storage::Book::Book;
#>> use common::sense;
#>> use aliased 'Liberia::Storage::Author::Author';
#>> 
#>> use Aion;
#>> 
#>> with 'Aion::Aya';
#>> 
#>> # Books of the Liberia
#>> presents 'books';
#>> 
#>> # The identifier
#>> has id => (is => 'ro', isa => Nat, pk => 1, next => -auto_increment);
#>> 
#>> # Name of a book
#>> has title => (is => 'rw', isa => NonEmptyStr, col => 1, unique => 1);
#>> 
#>> # Author who written a book
#>> has author => (is => 'rw', isa => Author, ref => -books);
#>> 
#>> # Co-authors who written a book with an author
#>> has coauthors => (
#>> 	is => 'rw',
#>> 	isa => ArrayRef[Author],
#>> 	m2n => {table => -co_authors_books, ref => -cobooks});
#>> 
#>> 1;
#@< EOF
# 
# Файл lib/Liberia/Storage/Book/BookBox.pm:
#@> lib/Liberia/Storage/Book/BookBox.pm
#>> package Liberia::Storage::Book::BookBox;
#>> use common::sense;
#>> use aliased 'Liberia::Storage::Book::Book';
#>> 
#>> use Aion;
#>> 
#>> with 'Aion::Aya::Box';
#>> 
#>> box_for Book;
#>> 
#>> sub all {
#>> 	my ($self) = @_;
#>> 
#>> 	@{$self->query_builder}
#>> }
#>> 
#>> sub get_title_on_P {
#>> 	my ($self) = @_;
#>> 
#>> 	$self->query_builder
#>> 		->join(author => 'a')
#>> 		->filter(F"a.name" =~ 'P%' | F"a.name" =~ qr/^P/)
#>> 		->scalar(-title);
#>> }
#>> 
#>> 1;
#@< EOF
# 
# Файл lib/Liberia/Action/BookAction.pm:
#@> lib/Liberia/Action/BookAction.pm
#>> package Liberia::Action::BookAction;
#>> use common::sense;
#>> use aliased 'Liberia::Storage::Author::Author';
#>> use aliased 'Liberia::Storage::Book::Book';
#>> use aliased 'Liberia::Storage::Book::BookBox';
#>> 
#>> use Aion;
#>> 
#>> # Entity manager
#>> has appearance => (is => 'ro', isa => 'Aion::Aya::Appearance', eon => 1);
#>> 
#>> # Book repository
#>> has book_box => (is => 'ro', isa => BookBox, eon => 1);
#>> 
#>> #@method POST /v1/books
#>> sub create {
#>> 	my ($self) = @_;
#>> 
#>> 	my $author = Author->new(name => 'Pushkin A.S.');
#>> 	my $book = Book
#>> 		->new(title => 'On the edge of Enchanted Wood, a green oak stands')
#>> 		->author($author);
#>> 
#>> 	$self->appearance->persist($author, $book)->flush;
#>> }
#>> 
#>> #@method GET /v1/books
#>> sub list {
#>> 	my ($self) = @_;
#>> 
#>> 	map +{
#>> 		id => $_->id,
#>> 		title => $_->title,
#>> 	}, $self->book_box->all;
#>> }
#>> 
#>> #@method GET /v1/books/title
#>> sub title {
#>> 	my ($self) = @_;
#>> 
#>> 	$self->book_box->get_title_on_P;
#>> }
#>> 
#>> 1;
#@< EOF
# 
# Код:
subtest 'SYNOPSIS' => sub { 
use common::sense;

use aliased 'Liberia::Action::BookAction';

my $book_action = BookAction->new;
$book_action->create;
local ($::_g0 = do {scalar $book_action->list}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar $book_action->list # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$book_action->title}, $::_e0 = "On the edge of Enchanted Wood, a green oak stands"); ::ok $::_g0 eq $::_e0, '$book_action->title # => On the edge of Enchanted Wood, a green oak stands' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Aya` — это ORM который реализует паттерны **Единица работы** и **Шлюз к данным таблицы**.
# 
# ORM использует идеи `Doctrine` и `Hibernate` через **Менеджер сущностей** и .
# 
# 1. **Identity Map** (Карта идентичности)
#    *Суть:* Кэш первого уровня.
#    *Зачем:* Гарантирует, что каждый объект загружается из базы данных только один раз за транзакцию. Повторный запрос вернет ту же самую ссылку на объект в памяти.
# 2. **Lazy Load** (Отложенная загрузка)
#    *Суть:* Загрузка связанных данных (например, комментариев к статье) только в момент обращения к ним.
#    *Реализация:* Используются Proxy-объекты (заглушки), которые перехватывают обращение к свойствам и делают запрос в БД.
# 3. **Foreign Key Mapping** (Отображение внешнего ключа)
#    *Суть:* Превращение связей между таблицами (внешних ключей) в объектные связи (коллекции или ссылки на другие объекты).
#    *Примеры:* Связи многие-к-одному, один-ко-многим, многие-ко-многим.
# 4. **Metadata Mapping** (Отображение метаданных)
#    *Суть:* Вынесение правил соответствия полей классов и колонок таблиц в отдельное место.
#    *Реализация:* Настройки через атрибуты/аннотации в коде, XML-файлы или YAML-конфигурации.
# 5. **Identity Field** (Поле идентичности)
#    *Суть:* Обязательное наличие у каждого сохраняемого объекта уникального идентификатора (первичного ключа), который связывает объект в памяти со строкой в таблице.
# 
# # SUBROUTINES
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <dart@cpan.org>
# 
# # LICENSE
# 
# ⚖ **Perl5**
# 
# # COPYRIGHT
# 
# The Aion::Aya module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
