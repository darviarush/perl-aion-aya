use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-5]); 	my $project_name = $dirs[$#dirs-5]; 	my @test_dirs = @dirs[$#dirs-5+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Aya::Adapter::Diff::MemDiff - сравнение моделей со структурой DBD::Mem и генерация DDL
# 
# # SYNOPSIS
# 
# Файл lib/DiffExample.pm:
#@> lib/DiffExample.pm
#>> package DiffExample;
#>> use common::sense;
#>> 
#>> use Aion;
#>> use Aion::Aya::Table;
#>> use Aion::Aya::Adapter::Diff::MemDiff;
#>> use Aion::Aya::Adapter::Transform::SQL;
#>> 
#>> # MemDiff берёт экранирование у transformator адаптера, поэтому нужен adapter
#>> package DiffAdapter {
#>> 	use Aion;
#>> 	with 'Aion::Aya::Adapter';
#>> 
#>> 	has adapter => (is => 'ro', isa => 'Aion::Aya::Adapter', default => sub { undef });
#>> 	has transformator => (is => 'ro', isa => 'Aion::Aya::Adapter::Transform::Abstract', default => sub { Aion::Aya::Adapter::Transform::SQL->new });
#>> 	sub iterator :Isa(Me => Object['Aion::Aya::Query'] => Object['Aion::Aya::Iterator']) { }
#>> 	sub execute :Isa(Me => Object['Aion::Aya::Query'] => PositiveInt) { }
#>> 	sub next_val :Isa(Me => Object['Aion::Aya'] => Str) { }
#>> 	sub next :Isa(Me => Hashref => Any) { }
#>> }
#>> 
#>> package DiffExample;
#>> our $diff = bless { adapter => DiffAdapter->new }, 'Aion::Aya::Adapter::Diff::MemDiff';
#>> 
#>> our $book = Aion::Aya::Table->new(
#>> 	table => 'book',
#>> 	primary_key => {columns => ['id'], options => []},
#>> 	columns => [
#>> 		{name => 'id', type => 'int', is_nullable => 0, default => '', options => '', comment => '', order => 0},
#>> 		{name => 'title', type => 'varchar(255)', is_nullable => 0, default => '', options => '', comment => '', order => 1},
#>> 	],
#>> );
#>> 
#>> 1;
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use DiffExample;

my $ddl = $DiffExample::diff->diff({book => $DiffExample::book}, {});

local ($::_g0 = do {ref $ddl}, $::_e0 = do {'ARRAY'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $ddl  # -> \'ARRAY\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar @$ddl}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar @$ddl # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ddl->[0] =~ /^CREATE TABLE book/}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ddl->[0] =~ /^CREATE TABLE book/ # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `MemDiff` — реализация `Aion::Aya::Adapter::Diff::Abstract` для in-memory базы на `DBD::Mem`. Модуль умеет две вещи:
# 
# - **сравнивать** набор моделей с набором таблиц базы (`diff`) и возвращать DDL, приводящий базу к моделям;
# - **строить текст DDL** по описанию таблицы (`Aion::Aya::Table`): `CREATE TABLE`, `DROP TABLE`, `ALTER TABLE`, столбцы, ключи, внешние ключи.
# 
# `Aion::Aya::Adapter::Diff::MysqlDiff` наследует `MemDiff` и меняет только `model2table` (добавляет комментарии из аннотаций).
# 
# DDL-методы собирают текст, а имена экранируются через `word`, который делегирует `adapter->transformator->word`. Поэтому `MemDiff` держат рядом с `adapter`.
# 
# # FEATURES
# 
# ## adapter
# 
# Адаптер, у которого берутся соединение (`connect`/`finish`), трансформер (`word`) и метаданные. Наследуется от `Abstract`.
# 
# # SUBROUTINES
# 
# ## diff ($models, $database)
# 
# Сравнивает два хеша «имя таблицы => `Aion::Aya::Table`»: модели и текущую структуру базы. Возвращает ссылку на массив DDL:
# 
# - таблица есть в моделях, но нет в базе → `CREATE TABLE`;
# - таблица есть в базе, но нет в моделях → `DROP TABLE`;
# - одинаковые таблицы → ничего.
# 
# Изменения внутри существующих таблиц (ALTER) пока не вычисляются.
# 
::done_testing; }; subtest 'diff ($models, $database)' => sub { 
use DiffExample;

my $ddl = $DiffExample::diff->diff({book => $DiffExample::book}, {});

local ($::_g0 = do {scalar @$ddl}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar @$ddl # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$ddl->[0] =~ /^CREATE TABLE book/}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$ddl->[0] =~ /^CREATE TABLE book/ # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Одинаковые структуры — пустой список
my $same = $DiffExample::diff->diff({book => $DiffExample::book}, {book => $DiffExample::book});

local ($::_g0 = do {scalar @$same}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar @$same # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## model2table ($model)
# 
# Строит `Aion::Aya::Table` из модели (`Aion::Aya::Model`): перебирает `col`-поля по `order`, берёт типы через `isa2type`, учитывает `Maybe` (nullable) и первичный ключ. У `MemDiff` нет комментариев и опций, потому что `DBD::Mem` их не поддерживает.
# 
::done_testing; }; subtest 'model2table ($model)' => sub { 
use DiffExample;

local ($::_g0 = do {ref $DiffExample::diff->can('model2table')}, $::_e0 = do {'CODE'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $DiffExample::diff->can(\'model2table\') # -> \'CODE\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## structure ()
# 
# Читает структуру таблиц из `DBD::Mem` (`table_info`/`column_info`) и возвращает хеш «имя => `Aion::Aya::Table`». Требует работающего `adapter->connect`.
# 
# ## isa2type ($isa)
# 
# Преобразует тип Aion в имя SQL-типа. Для `DBD::Mem` поддерживаются `Int`, `TinyInt`, `LongInt` (`int`/`tinyint`/`int`); неизвестный тип — исключение `Not convert isa … to type!`.
# 
::done_testing; }; subtest 'isa2type ($isa)' => sub { 
use DiffExample;
use Aion::Aya::Types;

local ($::_g0 = do {$DiffExample::diff->isa2type(Int())}, $::_e0 = do {'int'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->isa2type(Int())     # -> \'int\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$DiffExample::diff->isa2type(TinyInt())}, $::_e0 = do {'tinyint'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->isa2type(TinyInt()) # -> \'tinyint\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$DiffExample::diff->isa2type(LongInt())}, $::_e0 = do {'int'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->isa2type(LongInt()) # -> \'int\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## get_tables ()
# 
# Возвращает имена таблиц базы через `table_info`. Используется в `structure`.
# 
# ## get_columns ($table)
# 
# Возвращает описание столбцов таблицы через `column_info`: `name`, `type`, `is_nullable`, `default` (из `SQL::Statement`), `order`. `options`/`comment` всегда пусты.
# 
# ## get_indexes ($table)
# 
# Заготовка: читает первичный ключ через `primary_key_info` и статистику через `statistics_info`, но индексы пока не возвращает.
# 
# ## word ($word)
# 
# Экранирование имени таблицы/колонки: делегирует `adapter->transformator->word`.
# 
# ## show_create_table ($table)
# 
# `CREATE TABLE {таблица} (\n{столбцы, первичный ключ, индексы, внешние ключи}\n)`.
# 
::done_testing; }; subtest 'show_create_table ($table)' => sub { 
use DiffExample;

my $sql = $DiffExample::diff->show_create_table($DiffExample::book);

local ($::_g0 = do {$sql =~ /^CREATE TABLE book \(/}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sql =~ /^CREATE TABLE book \(/ # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$sql =~ /PRIMARY KEY \(id\)/}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sql =~ /PRIMARY KEY \(id\)/     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_drop_table ($table)
# 
# `DROP TABLE {таблица}`.
# 
::done_testing; }; subtest 'show_drop_table ($table)' => sub { 
use DiffExample;

local ($::_g0 = do {$DiffExample::diff->show_drop_table($DiffExample::book)}, $::_e0 = do {'DROP TABLE book'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_drop_table($DiffExample::book) # -> \'DROP TABLE book\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_rename_table ($table, $to)
# 
# `ALTER TABLE {таблица} RENAME TO {новое имя}`.
# 
::done_testing; }; subtest 'show_rename_table ($table, $to)' => sub { 
use DiffExample;

local ($::_g0 = do {$DiffExample::diff->show_rename_table($DiffExample::book, 'book2')}, $::_e0 = do {'ALTER TABLE book RENAME TO book2'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_rename_table($DiffExample::book, \'book2\') # -> \'ALTER TABLE book RENAME TO book2\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_truncate_table ($table)
# 
# Очищает таблицу: `DELETE FROM {таблица}`.
# 
::done_testing; }; subtest 'show_truncate_table ($table)' => sub { 
use DiffExample;

local ($::_g0 = do {$DiffExample::diff->show_truncate_table($DiffExample::book)}, $::_e0 = do {'DELETE FROM book'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_truncate_table($DiffExample::book) # -> \'DELETE FROM book\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_modify_table ($table)
# 
# `ALTER TABLE {таблица} ` + опции таблицы. В `DBD::Mem` опций нет (`show_definition_table` возвращает пустую строку), поэтому получается `ALTER TABLE book `.
# 
::done_testing; }; subtest 'show_modify_table ($table)' => sub { 
use DiffExample;

local ($::_g0 = do {$DiffExample::diff->show_modify_table($DiffExample::book)}, $::_e0 = do {'ALTER TABLE book '}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_modify_table($DiffExample::book) # -> \'ALTER TABLE book \'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_create_definition ($table)
# 
# Внутренности `CREATE TABLE`: столбцы, `PRIMARY KEY`, индексы (`unique_keys`, `index_keys`), внешние ключи, соединённые через `,\n`.
# 
::done_testing; }; subtest 'show_create_definition ($table)' => sub { 
use DiffExample;

my $t = Aion::Aya::Table->new(
	table => 'book',
	primary_key => {columns => ['id'], options => []},
	columns => [{name => 'id', type => 'int', is_nullable => 0, default => '', options => '', comment => '', order => 0}],
	index_keys => [{name => 'idx_book', columns => ['title'], options => []}],
);

local ($::_g0 = do {$DiffExample::diff->show_create_definition($t) =~ /PRIMARY KEY \(id\),\nKEY idx_book \(title\)/}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_create_definition($t) =~ /PRIMARY KEY \(id\),\nKEY idx_book \(title\)/ # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_definition_table ($table, $create)
# 
# Опции таблицы. В `MemDiff` всегда пустая строка; наследники могут переопределить.
# 
# ## show_column ($col)
# 
# Столбец с именем: `{имя} {тип [NOT NULL] [DEFAULT …] [опции]}`.
# 
::done_testing; }; subtest 'show_column ($col)' => sub { 
use DiffExample;

local ($::_g0 = do {$DiffExample::diff->show_column({name => 'id', type => 'int', is_nullable => 0})}, $::_e0 = do {'id int NOT NULL'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_column({name => \'id\', type => \'int\', is_nullable => 0}) # -> \'id int NOT NULL\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_definition_column ($col, $with_keys)
# 
# Определение столбца без имени: тип (по умолчанию `TEXT`), `NOT NULL`, `DEFAULT`, опции.
# 
::done_testing; }; subtest 'show_definition_column ($col, $with_keys)' => sub { 
use DiffExample;

local ($::_g0 = do {$DiffExample::diff->show_definition_column({type => 'int', is_nullable => 0, default => 7})}, $::_e0 = do {'int NOT NULL DEFAULT 7'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_definition_column({type => \'int\', is_nullable => 0, default => 7}) # -> \'int NOT NULL DEFAULT 7\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_index ($index)
# 
# Индекс с именем: `KEY {имя} ({колонки})`.
# 
::done_testing; }; subtest 'show_index ($index)' => sub { 
use DiffExample;

local ($::_g0 = do {$DiffExample::diff->show_index({name => 'idx_book', columns => ['title']})}, $::_e0 = do {'KEY idx_book (title)'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_index({name => \'idx_book\', columns => [\'title\']}) # -> \'KEY idx_book (title)\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_definition_index ($index)
# 
# Индекс без имени: `({колонки})`.
# 
# ## show_foreign ($fk)
# 
# Внешний ключ с именем: `CONSTRAINT {имя} FOREIGN KEY ({колонки}) REFERENCES {таблица} ({колонки})`.
# 
::done_testing; }; subtest 'show_foreign ($fk)' => sub { 
use DiffExample;

local ($::_g0 = do {$DiffExample::diff->show_foreign({name => 'fk_book_author', to_table => 'author', columns => ['author_id'], to_columns => ['id']})}, $::_e0 = do {'CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES author (id)'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$DiffExample::diff->show_foreign({name => \'fk_book_author\', to_table => \'author\', columns => [\'author_id\'], to_columns => [\'id\']}) # -> \'CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES author (id)\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## show_definition_foreign ($fk)
# 
# Внешний ключ без имени: `FOREIGN KEY (...) REFERENCES ... (...)`.
# 
# ## show_create_database / show_drop_database / show_modify_database / show_definition_database
# 
# DDL для базы (`CREATE DATABASE`, `DROP DATABASE`, `ALTER DATABASE`). `show_definition_database` отдаёт пары `DEFAULT CHARACTER SET`/`DEFAULT COLLATE`, если у объекта есть `charset`/`collation`.
# 
# # GOTCHAS
# 
# * **`MemDiff->new` падает.** `model2table` в `MemDiff` объявлен как `:Isa(Me => Model => Table)`, а контракт `Abstract` — как `:Isa(Me => Model => Table)` с типом `Aion::Aya::Model`; сигнатуры не совпадают (`Signature mismatch`). Плюс `Model` в сигнатуре разрешается в несуществующий `Object['Model']`. Поэтому в примерах объект создаётся через `bless`, а `model2table` пока не работает.
# * **`adapter` обязателен для `word`.** DDL-методы зовут `word` → `adapter->transformator->word`, поэтому `adapter` нужен даже для чистой генерации текста.
# * **`diff` работает только для `Aion::Aya::Table`.** Оба аргумента проверяются как `HashRef[Object['Aion::Aya::Table']]`, поэтому передавать хеши столбцов вместо объектов нельзя.
# * **ALTER существующих таблиц не реализован.** `diff` делает только `CREATE`/`DROP`; изменения столбцов/индексов — `TODO`.
# * **`structure` требует рабочего соединения.** Он ходит в `adapter->connect` и `DBD::Mem`, поэтому в отрыве от базы не проверяется.
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
# The Aion::Aya::Adapter::Diff::MemDiff module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
