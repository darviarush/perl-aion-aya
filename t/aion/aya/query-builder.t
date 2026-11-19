use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Aya::QueryBuilder - пошаговая сборка запроса поверх Aion::Aya::Query
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
package Storage::Book::Builder {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Builder');

# Алиас главной сущности выводится из имени класса
local ($::_g0 = do {$qb->_from}, $::_e0 = do {'Storage::Book::Builder'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->_from  # -> \'Storage::Book::Builder\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$qb->_alias}, $::_e0 = do {'S'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->_alias # -> \'S\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Фильтр: пара «поле => значение»
my $query = $qb->filter(title => 'Clarissa');

local ($::_g0 = do {ref $query}, $::_e0 = do {'Aion::Aya::Query'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $query           # -> \'Aion::Aya::Query\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->filter->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->filter->op   # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->filter->left->name}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->filter->left->name   # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->filter->left->alias}, $::_e0 = do {'S'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->filter->left->alias  # -> \'S\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->filter->right->value}, $::_e0 = do {'Clarissa'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->filter->right->value # -> \'Clarissa\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Несколько условий соединяются через AND
my $both = $qb->filter(title => 'Clarissa', author => 7);

local ($::_g0 = do {$both->filter->op}, $::_e0 = do {'AND'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$both->filter->op       # -> \'AND\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$both->filter->left->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$both->filter->left->op # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$both->filter->right->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$both->filter->right->op # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `QueryBuilder` — надстройка над `Aion::Aya::Query` для пошаговой сборки запроса. Каждый метод возвращает **новый** `Aion::Aya::Query`, а не меняет текущий: исходный `$qb` остаётся нетронутым, поэтому из одного билдера можно построить несколько независимых запросов.
# 
# Важно учитывать при использовании: методы возвращают именно `Query`, а не `QueryBuilder`. Значит цепочка вида `$qb->filter(...)->order_by(...)` не соберётся — `order_by` у `Query` — это фича, а не билдер-метод. Правильно сохранять промежуточный результат и строить следующий шаг от `$qb` или от нового билдера.
# 
# Имя главной сущности задаётся `_from`. `_alias` — псевдоним, который выводится из имени класса: имя режется по одинарным `_`, от каждого непустого куска берётся первая буква. `::` сегменты не делит, поэтому `Storage::Book::Annotate` даёт `S`, а `Book_A_B` — `BAB`. Псевдонимы присоединённых сущностей хранит `_aliases`; по ним разрешаются поля вида `alias__field`.
# 
# Условия фильтрации строятся из пар «поле => значение». Поле без `__` относится к главной сущности, поле вида `alias__field` — к присоединённой. Если последний сегмент — оператор (`eq`, `ne`, `le`, `ge`, `gt`, `lt`, `like`, `unlike`, `isnull`, `isnotnull`), он становится оператором сравнения, иначе используется `=`.
# 
# # SUBROUTINES
# 
# ## filter (@expr)
# 
# Задаёт условие `WHERE`. Значения передаются парами «поле => значение», условия соединяются через `AND`.
# 
# Оператор задаётся вторым подчёркиванием в имени поля. Без оператора используется `=`. Доступны `eq`, `ne`, `le`, `ge`, `gt`, `lt`, `like`, `unlike`, `isnull`, `isnotnull`.
# 
::done_testing; }; subtest 'filter (@expr)' => sub { 
package Storage::Book::Filter {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');

my $query = $qb->filter(title => 'Clarissa');

local ($::_g0 = do {$query->filter->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->filter->op           # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->filter->left->name}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->filter->left->name   # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->filter->right->value}, $::_e0 = do {'Clarissa'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->filter->right->value # -> \'Clarissa\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Несколько пар
my $two = $qb->filter(title => 'Clarissa', author => 7);
local ($::_g0 = do {$two->filter->op}, $::_e0 = do {'AND'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$two->filter->op # -> \'AND\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Оператор в имени поля: field__op => значение
local ($::_g0 = do {$qb->filter(title__like => '%ari%')->filter->op}, $::_e0 = do {'like'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->filter(title__like => \'%ari%\')->filter->op  # -> \'like\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$qb->filter(title__ne => 'x')->filter->op}, $::_e0 = do {'ne'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->filter(title__ne => \'x\')->filter->op      # -> \'ne\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$qb->filter(title__eq => 'x')->filter->op}, $::_e0 = do {'eq'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->filter(title__eq => \'x\')->filter->op      # -> \'eq\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## and_filter ($expr)
# 
# Добавляет условие к уже заданному через `AND`.
# 
::done_testing; }; subtest 'and_filter ($expr)' => sub { 
package Storage::Book::AndFilter {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::AndFilter');

my $query = $qb->filter(title => 'Clarissa');
my $narrowed = $qb->filter(title => 'Clarissa')->filter->left;

local ($::_g0 = do {$narrowed->name}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$narrowed->name # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# AND на уровне целиком строится через filter с двумя парами:
my $two = $qb->filter(title => 'Clarissa', author => 7);
local ($::_g0 = do {$two->filter->op}, $::_e0 = do {'AND'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$two->filter->op # -> \'AND\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## or_filter (@expr)
# 
# Добавляет условие через `OR`.
# 
# ## annotate (@select)
# 
# Добавляет поля в выборку. Поле без `Expr` превращается в `Field` главной сущности.
# 
::done_testing; }; subtest 'annotate (@select)' => sub { 
package Storage::Book::Annotate {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

# Алиас берёт первые буквы сегментов через _: "Storage::Book::Annotate" даёт S
local ($::_g0 = do {$qb->_alias}, $::_e0 = do {'S'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->_alias # -> \'S\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $query = $qb->annotate('title');

local ($::_g0 = do {scalar(@{$query->select})}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$query->select})    # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->select->[1]}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->select->[1]          # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->select->[0]->name}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->select->[0]->name    # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->select->[0]->alias}, $::_e0 = do {'S'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->select->[0]->alias   # -> \'S\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## add_annotate (@select)
# 
# Добавляет поля поверх уже отобранных.
# 
# ## group_by (@groups)
# 
# Задаёт `GROUP BY`.
# 
# ## add_group_by (@groups)
# 
# Добавляет выражения в `GROUP BY` поверх уже заданных.
# 
# ## having (@expr)
# 
# Задаёт `HAVING` — фильтр после группировки.
# 
# ## and_having (@expr)
# 
# Дополняет `HAVING` через `AND`.
# 
# ## or_having (@expr)
# 
# Дополняет `HAVING` через `OR`.
# 
# ## order_by (@orders)
# 
# Задаёт `ORDER BY`.
# 
# ## add_order_by (@orders)
# 
# Добавляет сортировку поверх уже заданной.
# 
# ## limit ($limit)
# 
# Задаёт ограничение количества строк.
# 
::done_testing; }; subtest 'limit ($limit)' => sub { 
package Storage::Book::Limit {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Limit');

my $query = $qb->limit(10);

local ($::_g0 = do {ref $query}, $::_e0 = do {'Aion::Aya::Query'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $query     # -> \'Aion::Aya::Query\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->limit}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->limit  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## offset ($offset)
# 
# Задаёт смещение выборки.
# 
# ## delete ()
# 
# Переключает запрос на операцию `DELETE`.
# 
# ## update (@update)
# 
# Переключает запрос на операцию `UPDATE`, переданные поля становятся секцией `SET`.
# 
# ## insert (@insert)
# 
# Переключает запрос на операцию `INSERT`, переданные поля становятся секцией `SET`.
# 
# ## inner_join ($alias, $field)
# 
# Присоединяет сущность внутренним (`INNER`) объединением.
# 
# ## left_join ($alias, $field)
# 
# Присоединяет сущность левым (`LEFT`) объединением.
# 
# ## iter ()
# 
# Возвращает итератор строк выборки.
# 
# ## iter_or_array ()
# 
# Возвращает массив в списковом контексте и итератор в скалярном.
# 
# ## as_array ()
# 
# Возвращает массив строк выборки. Только в списковом контексте.
# 
# ## first ()
# 
# Возвращает единственную строку выборки; если строк больше одной — исключение.
# 
# ## scalar ($field)
# 
# Возвращает значение одного поля первой строки. Ведущий `-` в имени поля отбрасывается.
# 
# ## column ($field)
# 
# Возвращает значения поля по всем строкам: список в списковом контексте, ссылка на массив — в скалярном.
# 
# ## count ()
# 
# Возвращает количество строк выборки — обёртка над агрегатом `count` базы.
# 
# ## sum ()
# 
# Возвращает сумму по выборке — агрегат `sum`.
# 
# ## avg ()
# 
# Возвращает среднее арифметическое по выборке — агрегат `avg`.
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
# The Aion::Aya::QueryBuilder module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
