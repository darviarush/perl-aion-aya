use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-5]); 	my $project_name = $dirs[$#dirs-5]; 	my @test_dirs = @dirs[$#dirs-5+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Aya::Adapter::Transform::SQL - превращение Aion::Aya::Query в SQL-текст (DQL и DML)
# 
# # SYNOPSIS
# 
# Файл lib/ExEntity.pm:
#@> lib/ExEntity.pm
#>> package ExEntity;
#>> 
#>> use common::sense;
#>> 
#>> use Aion with => 'Aion::Aya';
#>> 
#>> presents 'books';
#>> 
#>> has id => (is => 'ro', isa => PositiveInt, pk => 1);
#>> has title => (is => 'ro', isa => Str & Len[255], col => 1);
#>> 
#>> 1;
#@< EOF
# 
# Код:
# 
subtest 'SYNOPSIS' => sub { 
use ExEntity;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Adapter::Transform::SQL' => 'TransformSQL';

my $transformator = TransformSQL->new;
my $query = Query->new(from => 'ExEntity');

local ($::_g0 = do {$transformator->sql_select($query)}, $::_e0 = "SELECT * FROM books"); ::ok $::_g0 eq $::_e0, '$transformator->sql_select($query) # => SELECT * FROM books' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$transformator->sql_delete($query)}, $::_e0 = "DELETE FROM books"); ::ok $::_g0 eq $::_e0, '$transformator->sql_delete($query) # => DELETE FROM books' or ::diag ::_string_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Aya::Adapter::Transform::SQL` — конкретная реализация контракта `Aion::Aya::Adapter::Transform::Abstract`: берёт `Aion::Aya::Query` и отдаёт строку SQL для DQL (`SELECT`) и DML (`INSERT`, `UPDATE`, `DELETE`).
# 
# Роль различает диалекты через переопределяемые методы:
# 
# - `word` — как писать имя таблицы/колонки (по умолчанию без экранирования);
# - `is_keyword` — считать ли имя ключевым словом (по умолчанию никогда);
# - `quoteword` — как экранировать имя, если оно ключевое (по умолчанию обратные кавычки).
# 
# `Aion::Aya::Adapter::Transform::Mem` и `Aion::Aya::Adapter::Transform::Mysql` наследуют SQL и меняют только экранирование (`Mysql` экранирует обратными кавычками).
# 
# Имя таблицы и колонки берутся из `Aion::Aya::Model` (`Model->get($query->from)->table` и `col_name`), поэтому переименование колонки в модели не ломает SQL.
# 
# # SUBROUTINES
# 
# ## transform ($query)
# 
# Превращает запрос в строку SQL. Диспетчеризует по `$query->operation`: `SELECT` → `sql_select`, `INSERT` → `sql_insert`, `UPDATE` → `sql_update`, `DELETE` → `sql_delete`.
# 
::done_testing; }; subtest 'transform ($query)' => sub { 
my $t = TransformSQL->new;
my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');

my $select = Query->new(from => 'ExEntity');

local ($::_g0 = do {$t->sql_select($select)}, $::_e0 = do {'SELECT * FROM books'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->sql_select($select) # -> \'SELECT * FROM books\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $delete = Query->new(from => 'ExEntity');

local ($::_g0 = do {$t->sql_delete($delete)}, $::_e0 = do {'DELETE FROM books'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->sql_delete($delete) # -> \'DELETE FROM books\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$t->sql_insert(Query->new(from => 'ExEntity', operation => 'insert', select => [($val, 'title')]))}, $::_e0 = do {'INSERT INTO books (title) VALUES (Clarissa)'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->sql_insert(Query->new(from => \'ExEntity\', operation => \'insert\', select => [($val, \'title\')])) # -> \'INSERT INTO books (title) VALUES (Clarissa)\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## sql_select ($query)
# 
# Строит `SELECT`: `SELECT <поля|*> FROM [таблица](https://metacpan.org/pod/таблица)` и общую часть (см. `_select`). Поля задаются парами «выражение → псевдоним».
# 
::done_testing; }; subtest 'sql_select ($query)' => sub { 
my $t = TransformSQL->new;
my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');

my $query = Query->new(from => 'ExEntity', select => [($val, 'ttl')]);

local ($::_g0 = do {$t->sql_select($query)}, $::_e0 = do {'SELECT Clarissa as ttl FROM books'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->sql_select($query) # -> \'SELECT Clarissa as ttl FROM books\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## sql_insert ($query)
# 
# Строит `INSERT INTO [таблица](https://metacpan.org/pod/таблица) (<колонки>) VALUES (<значения>)`. Пары `select` — это значение и имя колонки.
# 
::done_testing; }; subtest 'sql_insert ($query)' => sub { 
my $t = TransformSQL->new;
my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');

local ($::_g0 = do {$t->sql_insert(Query->new(from => 'ExEntity', operation => 'insert', select => [($val, 'title')]))}, $::_e0 = do {'INSERT INTO books (title) VALUES (Clarissa)'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->sql_insert(Query->new(from => \'ExEntity\', operation => \'insert\', select => [($val, \'title\')])) # -> \'INSERT INTO books (title) VALUES (Clarissa)\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## sql_update ($query)
# 
# Строит `UPDATE [таблица](https://metacpan.org/pod/таблица) SET [колонка](https://metacpan.org/pod/колонка) = [значение](https://metacpan.org/pod/значение)` и общую часть. Пары `select` — значение и имя колонки.
# 
# ## sql_delete ($query)
# 
# Строит `DELETE FROM [таблица](https://metacpan.org/pod/таблица)` и общую часть.
# 
::done_testing; }; subtest 'sql_delete ($query)' => sub { 
my $t = TransformSQL->new;

my $query = Query->new(from => 'ExEntity');

local ($::_g0 = do {$t->sql_delete($query)}, $::_e0 = do {'DELETE FROM books'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->sql_delete($query) # -> \'DELETE FROM books\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## _select ($query)
# 
# Общая хвостовая часть для всех операций: соединения, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`, `OFFSET`.
# 
::done_testing; }; subtest '_select ($query)' => sub { 
my $t = TransformSQL->new;
my $query = Query->new(from => 'ExEntity', limit => 5, offset => 10);

local ($::_g0 = do {$t->sql_select($query)}, $::_e0 = do {'SELECT * FROM books LIMIT 5 OFFSET 10'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->sql_select($query) # -> \'SELECT * FROM books LIMIT 5 OFFSET 10\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## expr ($expr)
# 
# Превращает узел дерева выражений в SQL:
# 
# - `Val` — значение как есть;
# - `Field` — `alias.column`;
# - `UOp` — `op exp` (`NOT b.title`);
# - `Op` — `left op right` (`b.title=Clarissa`).
# 
::done_testing; }; subtest 'expr ($expr)' => sub { 
my $t = TransformSQL->new;
my $field = Aion::Aya::Query::Expr::Field->new(alias => 'b', name => 'title', entity => 'ExEntity');
my $val   = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');

local ($::_g0 = do {$t->expr($val)}, $::_e0 = do {'Clarissa'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->expr($val) # -> \'Clarissa\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$t->expr($field)}, $::_e0 = do {'b.title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->expr($field) # -> \'b.title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$t->expr(Aion::Aya::Query::Expr::Op->new(op => '=', left => $field, right => $val))}, $::_e0 = do {'b.title=Clarissa'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->expr(Aion::Aya::Query::Expr::Op->new(op => \'=\', left => $field, right => $val)) # -> \'b.title=Clarissa\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$t->expr(Aion::Aya::Query::Expr::UOp->new(op => 'NOT', exp => $field))}, $::_e0 = do {'NOT b.title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->expr(Aion::Aya::Query::Expr::UOp->new(op => \'NOT\', exp => $field)) # -> \'NOT b.title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## word ($word)
# 
# Пишет имя таблицы или колонки: экранирует через `quoteword`, если `is_keyword` истинно, иначе возвращает как есть.
# 
::done_testing; }; subtest 'word ($word)' => sub { 
my $t = TransformSQL->new;

local ($::_g0 = do {$t->word('books')}, $::_e0 = do {'books'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->word(\'books\') # -> \'books\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## is_keyword ($word)
# 
# Считает ли имя ключевым словом. В SQL по умолчанию — никогда; диалект переопределяет.
# 
::done_testing; }; subtest 'is_keyword ($word)' => sub { 
my $t = TransformSQL->new;

local ($::_g0 = do {$t->is_keyword('books')}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->is_keyword(\'books\') # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## quoteword ($word)
# 
# Экранирует ключевое слово. В SQL и MySQL — обратными кавычками.
# 
::done_testing; }; subtest 'quoteword ($word)' => sub { 
my $t = TransformSQL->new;

local ($::_g0 = do {$t->quoteword('books')}, $::_e0 = do {'`books`'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$t->quoteword(\'books\') # -> \'`books`\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # GOTCHAS
# 
# Библиотека в разработке, и у диалекта SQL сейчас есть ограничения:
# 
# * **Конструктор не создаётся.** `TransformSQL->new` падает с `Signature mismatch`: `transform` в `SQL` объявлен как `:Isa(Me => Query => Str)`, а контракт `Abstract` требует `Any`. Пока это не исправят, в примерах объект создаётся через `bless`, а `transform` вызвать нельзя.
# * **`transform` требует `Abstract`-объект.** Даже при `bless` вызов `transform` проверяет первый аргумент по типу из `Abstract` (`Object['Query']`) и падает, если `Query` не разрешается в класс. Поэтому в примерах показаны `sql_*` и `expr` напрямую.
# * **`join` должен быть хешем для `_select`.** `_select` делает `%{$query->{join}}`, а `Aion::Aya::Query` хранит `join` как массив, так что `sql_select` без правки `$query->{join} = {}` падает на `Not a HASH reference`.
# * **`insert` различает формы `join`.** `sql_insert` проверяет `@{$query->{join}}` (массив) для выбора `INSERT ... SELECT`, а затем вызывает `_select`, где `join` нужен хешем.
# * **`filter`/`having` в `_select` проверяются на истинность.** У `Aion::Aya::Query::Expr::Op` есть перегрузка `&{}` без `bool`, поэтому выражение в `filter` даёт `Operation "bool": no method found`.
# * **`ORDER BY` собирается из пар.** `Aion::Aya::Query` хранит `order_by` как пары «выражение — `ASC`/`DESC`», а `_select` склеивает их через `pairmap` с разделителем `' '`, поэтому в SQL попадает лишний разделитель.
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
# The Aion::Aya::Adapter::Transform::SQL module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
