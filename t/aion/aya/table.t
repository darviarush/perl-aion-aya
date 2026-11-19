use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Aya::Table - снимок структуры таблицы в базе: столбцы, ключи и внешние связи
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
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

local ($::_g0 = do {$table->table}, $::_e0 = do {'book'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->table                          # -> \'book\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$table->primary_key->{columns}->[0]}, $::_e0 = do {'id'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->primary_key->{columns}->[0]    # -> \'id\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar(@{$table->columns})}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$table->columns})             # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$table->columns->[1]->{name}}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->columns->[1]->{name}           # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$table->columns->[1]->{comment}}, $::_e0 = do {'Название'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->columns->[1]->{comment}        # -> \'Название\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$table->unique_keys->[0]->{name}}, $::_e0 = do {'unq_book_title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->unique_keys->[0]->{name}       # -> \'unq_book_title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$table->index_keys->[0]->{name}}, $::_e0 = do {'idx_book_title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->index_keys->[0]->{name}        # -> \'idx_book_title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$table->foreign_keys->[0]->{to_table}}, $::_e0 = do {'author'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->foreign_keys->[0]->{to_table}  # -> \'author\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$table->foreign_keys->[0]->{options}->[0]}, $::_e0 = do {'on delete cascade'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->foreign_keys->[0]->{options}->[0] # -> \'on delete cascade\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$table->options}, $::_e0 = do {'ENGINE=InnoDB'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$table->options                        # -> \'ENGINE=InnoDB\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Обязательные поля — `table`, `primary_key` и `columns`; их отсутствие даёт исключение:
# 

use Aion::Aya::Table;

eval {Aion::Aya::Table->new(columns => [])}; local ($::_g0 = $@, $::_e0 = 'table required'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'Aion::Aya::Table->new(columns => []) # @-> table required' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Aya::Table` — общий формат описания структуры таблицы. Один и тот же объект получается двумя путями:
# 
# - из модели (`Migration::Comparator->model2table`) — по метаданным `%Aion::Aya::META`;
# - из базы (`Migration::Comparator->structure`) — по системным каталогам `DBI`.
# 
# `diff` сравнивает два `HashRef[Aion::Aya::Table]` (модель и базу) и возвращает DDL-инструкции, которые приводят базу к модели. Поэтому именно здесь живёт контракт между метаданными, драйвером и миграциями.
# 
# # FEATURES
# 
# ## table
# 
# Имя таблицы в базе.
# 
# ## options
# 
# Опции таблицы в базе.
# 
# ## primary_key
# 
# Первичный ключ.
# 
# ## columns
# 
# Столбцы.
# 
# ## unique_keys
# 
# Уникальные ключи.
# 
# ## index_keys
# 
# Индексы.
# 
# ## foreign_keys
# 
# Внешние ключи.
# 
# # TYPES
# 
# ## Column
# 
# Столбец таблицы. Все поля обязательны.
# 
# - `name` — имя в базе;
# - `type` — тип SQL (`int`, `varchar(255)`);
# - `is_nullable` — допускает `NULL`;
# - `default` — значение по умолчанию;
# - `options` — дополнительные опции (`auto_increment`, `unsigned`);
# - `comment` — комментарий;
# - `order` — порядок в определении.
# 
::done_testing; }; subtest 'Column' => sub { 
my $col = {name => 'id', type => 'int', is_nullable => 0, default => '', options => 'auto_increment', comment => '', order => 0};

local ($::_g0 = do {$col ~~ Aion::Aya::Table::Column()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$col ~~ Aion::Aya::Table::Column() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Без обязательного поля type
my %no_type = %$col; delete $no_type{type};
local ($::_g0 = do {\%no_type ~~ Aion::Aya::Table::Column()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%no_type ~~ Aion::Aya::Table::Column() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Лишнее поле
my %extra = (%$col, extra => 1);
local ($::_g0 = do {\%extra ~~ Aion::Aya::Table::Column()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%extra ~~ Aion::Aya::Table::Column() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Неверный тип поля
my %bad_type = (%$col, is_nullable => 'maybe');
local ($::_g0 = do {\%bad_type ~~ Aion::Aya::Table::Column()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%bad_type ~~ Aion::Aya::Table::Column() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## OptionColumn
# 
# То же, что `Column`, но все поля необязательны — для чтения из базы, где часть сведений недоступна.
# 
::done_testing; }; subtest 'OptionColumn' => sub { 
my $empty = {};
local ($::_g0 = do {$empty ~~ Aion::Aya::Table::OptionColumn()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$empty ~~ Aion::Aya::Table::OptionColumn() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $name_only = {name => 'id'};
local ($::_g0 = do {$name_only ~~ Aion::Aya::Table::OptionColumn()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$name_only ~~ Aion::Aya::Table::OptionColumn() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $name_type = {name => 'id', type => 'int'};
local ($::_g0 = do {$name_type ~~ Aion::Aya::Table::OptionColumn()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$name_type ~~ Aion::Aya::Table::OptionColumn() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Тип проверяется, если поле задано
my %bad = (is_nullable => 'maybe');
local ($::_g0 = do {\%bad ~~ Aion::Aya::Table::OptionColumn()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%bad ~~ Aion::Aya::Table::OptionColumn() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## PrimaryKey
# 
# Первичный ключ. В отличие от `Key`, у него нет имени — в базе первичный ключ один.
# 
# - `columns` — список столбцов;
# - `options` — опции (`using` и т. п.).
# 
::done_testing; }; subtest 'PrimaryKey' => sub { 
my $pk = {columns => ['id'], options => []};

local ($::_g0 = do {$pk ~~ Aion::Aya::Table::PrimaryKey()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$pk ~~ Aion::Aya::Table::PrimaryKey() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Составной первичный ключ
my $composite_pk = {columns => ['author', 'title'], options => []};
local ($::_g0 = do {$composite_pk ~~ Aion::Aya::Table::PrimaryKey()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$composite_pk ~~ Aion::Aya::Table::PrimaryKey() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Без столбцов
my $no_cols = {options => []};
local ($::_g0 = do {$no_cols ~~ Aion::Aya::Table::PrimaryKey()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$no_cols ~~ Aion::Aya::Table::PrimaryKey() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Имени у первичного ключа нет
my $named = {name => 'pk', columns => ['id'], options => []};
local ($::_g0 = do {$named ~~ Aion::Aya::Table::PrimaryKey()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$named ~~ Aion::Aya::Table::PrimaryKey() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Key
# 
# Ключ таблицы: уникальный или обычный индекс.
# 
# - `name` — имя ключа;
# - `columns` — список столбцов;
# - `options` — опции (`using` и т. п.).
# 
::done_testing; }; subtest 'Key' => sub { 
my $key = {name => 'idx_xy', columns => ['pos_history', 'pos_action'], options => []};

local ($::_g0 = do {$key ~~ Aion::Aya::Table::Key()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$key ~~ Aion::Aya::Table::Key() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Без имени
my %no_name = %$key; delete $no_name{name};
local ($::_g0 = do {\%no_name ~~ Aion::Aya::Table::Key()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%no_name ~~ Aion::Aya::Table::Key() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Столбцы — не массив строк
my %not_array = (%$key, columns => 'pos_history');
local ($::_g0 = do {\%not_array ~~ Aion::Aya::Table::Key()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%not_array ~~ Aion::Aya::Table::Key() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;


# Составной ключ
my $composite = {name => 'pk', columns => ['author', 'title'], options => []};
local ($::_g0 = do {$composite ~~ Aion::Aya::Table::Key()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$composite ~~ Aion::Aya::Table::Key() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ForeignKey
# 
# Внешний ключ.
# 
# - `name` — имя ограничения;
# - `to_table` — таблица назначения;
# - `columns` — столбцы текущей таблицы;
# - `to_columns` — столбцы таблицы назначения;
# - `options` — опции (`on delete cascade`).
# 
::done_testing; }; subtest 'ForeignKey' => sub { 
my $fk = {name => 'fk_book_author', to_table => 'author', columns => ['author_id'], to_columns => ['id'], options => ['on delete cascade']};

local ($::_g0 = do {$fk ~~ Aion::Aya::Table::ForeignKey()}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$fk ~~ Aion::Aya::Table::ForeignKey() # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Без таблицы назначения
my %no_table = %$fk; delete $no_table{to_table};
local ($::_g0 = do {\%no_table ~~ Aion::Aya::Table::ForeignKey()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%no_table ~~ Aion::Aya::Table::ForeignKey() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Таблица назначения должна быть именем пакета
my %bad_table = (%$fk, to_table => 'Author Table');
local ($::_g0 = do {\%bad_table ~~ Aion::Aya::Table::ForeignKey()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%bad_table ~~ Aion::Aya::Table::ForeignKey() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Неверные столбцы
my %bad_cols = (%$fk, to_columns => 'id');
local ($::_g0 = do {\%bad_cols ~~ Aion::Aya::Table::ForeignKey()}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\%bad_cols ~~ Aion::Aya::Table::ForeignKey() # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Все пять типов — `Dict`, то есть проверяются при установке: незаявленный ключ или неверный тип дают исключение.
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
# The Aion::Aya::Table module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
