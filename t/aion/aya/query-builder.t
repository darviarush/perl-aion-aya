use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Aya::QueryBuilder - пошаговая сборка запроса поверх Aion::Aya::Query
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
package Storage::Book::Builder {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has id    => (is => 'ro', isa => Int, pk => 1, col => 1);
	has title => (is => 'ro', isa => Str, col => 1);
}

use Aion::Aya::QueryBuilder;

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Builder');

# Алиас главной сущности выводится из имени класса
local ($::_g0 = do {$qb->_from}, $::_e0 = do {'Storage::Book::Builder'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->_from  # -> \'Storage::Book::Builder\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$qb->_alias}, $::_e0 = do {'S'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->_alias # -> \'S\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Каждый шаг возвращает новый QueryBuilder — можно строить цепочку
my $query = $qb->filter(title => 'Clarissa')->limit(10);

local ($::_g0 = do {ref $query}, $::_e0 = do {'Aion::Aya::QueryBuilder'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $query                    # -> \'Aion::Aya::QueryBuilder\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->filter->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->filter->op    # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->filter->left->name}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->filter->left->name   # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->filter->left->alias}, $::_e0 = do {'S'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->filter->left->alias  # -> \'S\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->filter->right->value}, $::_e0 = do {'Clarissa'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->filter->right->value # -> \'Clarissa\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->{limit}}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->{limit}       # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Исходный билдер не изменяется
local ($::_g0 = do {$qb->_query->{limit}}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->_query->{limit} # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `QueryBuilder` — надстройка над `Aion::Aya::Query` для пошаговой сборки запроса. Каждый метод возвращает **новый `QueryBuilder`** (через `clone`), а не меняет текущий и не возвращает голый `Query`. Поэтому шаги можно объединять в цепочку: `$qb->filter(...)->limit(10)->offset(5)`, а исходный `$qb` остаётся нетронутым.
# 
# Сам запрос доступен у результата в фиче `_query`. Имя главной сущности задаётся `_from`; `_alias` — псевдоним, выводимый из имени класса: имя режется по одинарным `_`, от каждого непустого куска берётся первая буква. `::` сегменты не делит, поэтому `Storage::Book::Builder` даёт `S`, а `Book_A_B` — `BAB`. Псевдонимы присоединённых сущностей хранит `_aliases`.
# 
# Условия фильтрации строятся из пар «поле => значение». Поле без `__`/`.` относится к главной сущности, поле вида `alias__field`/`alias.field` — к присоединённой. Если последний сегмент — оператор (`eq`, `ne`, `le`, `ge`, `gt`, `lt`, `like`, `unlike`, `isnull`, `isnotnull`), он становится оператором сравнения, иначе используется `=`.
# 
# # SUBROUTINES
# 
# ## clone (%opt)
# 
# Клонирует билдер: запрос клонируется отдельно, алиасы копируются в новый хеш. Опции:
# 
# - `_query` — изменения для `Query->clone` (`{ operation => ..., limit => ... }`);
# - `aliases` — добавляемые/переопределяемые алиасы;
# - `self` — произвольные изменения самого билдера.
# 
::done_testing; }; subtest 'clone (%opt)' => sub { 
package Storage::Book::Clone {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has title => (is => 'ro', isa => Str, col => 1);
}

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Clone');

my $copy = $qb->clone(_query => { limit => 5 });

local ($::_g0 = do {ref $copy}, $::_e0 = do {'Aion::Aya::QueryBuilder'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $copy               # -> \'Aion::Aya::QueryBuilder\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$copy->_query->{limit}}, $::_e0 = do {5}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$copy->_query->{limit}  # -> 5' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$qb->_query->{limit}}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->_query->{limit}    # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## filter (@expr)
# 
# Задаёт условие `WHERE` из пар «поле => значение»; пары соединяются через `AND`. Оператор задаётся вторым `__` в имени поля.
# 
::done_testing; }; subtest 'filter (@expr)' => sub { 
package Storage::Book::Filter {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has title => (is => 'ro', isa => Str, col => 1);
}

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');

my $query = $qb->filter(title => 'Clarissa');

local ($::_g0 = do {$query->_query->filter->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->filter->op           # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->filter->left->name}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->filter->left->name   # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->filter->right->value}, $::_e0 = do {'Clarissa'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->filter->right->value # -> \'Clarissa\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $two = $qb->filter(title => 'Clarissa', title => 7);
local ($::_g0 = do {$two->_query->filter->op}, $::_e0 = do {'AND'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$two->_query->filter->op # -> \'AND\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$qb->filter(title__like => '%ari%')->_query->filter->op}, $::_e0 = do {'like'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->filter(title__like => \'%ari%\')->_query->filter->op # -> \'like\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$qb->filter(title__ne => 'x')->_query->filter->op}, $::_e0 = do {'ne'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->filter(title__ne => \'x\')->_query->filter->op       # -> \'ne\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## and_filter (@expr)
# 
# Добавляет условие через `AND`. Если предыдущего условия нет, ставит новое без `AND`.
# 
::done_testing; }; subtest 'and_filter (@expr)' => sub { 
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');

local ($::_g0 = do {$qb->and_filter(title => 'x')->_query->filter->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->and_filter(title => \'x\')->_query->filter->op # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $narrowed = $qb->filter(title => 'x')->and_filter(title => 'y');

local ($::_g0 = do {$narrowed->_query->filter->op}, $::_e0 = do {'AND'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$narrowed->_query->filter->op       # -> \'AND\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$narrowed->_query->filter->left->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$narrowed->_query->filter->left->op # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## or_filter (@expr)
# 
# Добавляет условие через `OR`. Если предыдущего условия нет, ставит новое без `OR`.
# 
::done_testing; }; subtest 'or_filter (@expr)' => sub { 
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');

local ($::_g0 = do {$qb->or_filter(title => 'x')->_query->filter->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->or_filter(title => \'x\')->_query->filter->op # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$qb->filter(title => 'x')->or_filter(title => 'y')->_query->filter->op}, $::_e0 = do {'OR'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->filter(title => \'x\')->or_filter(title => \'y\')->_query->filter->op # -> \'OR\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## annotate (@select)
# 
# Добавляет поля в выборку: `Expr => Str` или просто имя поля (превращается в поле главной сущности).
# 
::done_testing; }; subtest 'annotate (@select)' => sub { 
package Storage::Book::Annotate {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has title => (is => 'ro', isa => Str, col => 1);
}

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

my $query = $qb->annotate('title');

local ($::_g0 = do {scalar(@{$query->_query->select})}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$query->_query->select})    # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->select->[1]}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->select->[1]          # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->select->[0]->name}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->select->[0]->name    # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->select->[0]->alias}, $::_e0 = do {'S'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->select->[0]->alias   # -> \'S\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## add_annotate (@select)
# 
# Добавляет поля поверх уже отобранных.
# 
::done_testing; }; subtest 'add_annotate (@select)' => sub { 
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

my $query = $qb->annotate('title')->add_annotate('id');

local ($::_g0 = do {scalar(@{$query->_query->select})}, $::_e0 = do {4}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$query->_query->select}) # -> 4' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## group_by (@groups)
# 
# Задаёт `GROUP BY`.
# 
# ## add_group_by (@groups)
# 
# Добавляет выражения в `GROUP BY` поверх уже заданных.
# 
::done_testing; }; subtest 'add_group_by (@groups)' => sub { 
use aliased 'Aion::Aya::Query::Expr::Field';

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
my $t = Field->new(alias => 'S', name => 'title', entity => 'Storage::Book::Annotate');

my $query = $qb->group_by($t)->add_group_by($t);

local ($::_g0 = do {scalar(@{$query->_query->group_by})}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$query->_query->group_by}) # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
::done_testing; }; subtest 'or_having (@expr)' => sub { 
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

local ($::_g0 = do {$qb->having(title => 'x')->_query->having->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->having(title => \'x\')->_query->having->op # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$qb->having(title => 'x')->and_having(title => 'y')->_query->having->op}, $::_e0 = do {'AND'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$qb->having(title => \'x\')->and_having(title => \'y\')->_query->having->op # -> \'AND\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## order_by (@orders)
# 
# Задаёт `ORDER BY`. Значения — пары «выражение/поле => `ASC`|`DESC`».
# 
# ## add_order_by (@orders)
# 
# Добавляет сортировку поверх уже заданной.
# 
::done_testing; }; subtest 'add_order_by (@orders)' => sub { 
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
my $t = Field->new(alias => 'S', name => 'title', entity => 'Storage::Book::Annotate');

my $query = $qb->order_by($t => 'ASC')->add_order_by($t => 'DESC');

local ($::_g0 = do {scalar(@{$query->_query->order_by})}, $::_e0 = do {4}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$query->_query->order_by}) # -> 4' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## offset ($offset)
# 
# Задаёт смещение выборки.
# 
# ## limit ($limit)
# 
# Задаёт ограничение количества строк.
# 
::done_testing; }; subtest 'limit ($limit)' => sub { 
my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');

my $query = $qb->limit(10)->offset(2);

local ($::_g0 = do {$query->_query->{limit}}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->{limit}  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->_query->{offset}}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->_query->{offset} # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## delete ()
# 
# Переключает запрос на операцию `DELETE`.
# 
# ## update (@update)
# 
# Переключает запрос на `UPDATE`, переданные поля становятся секцией `SET`.
# 
# ## insert (@insert)
# 
# Переключает запрос на `INSERT`, переданные поля становятся секцией `SET`.
# 
# ## inner_join ($field, $alias)
# 
# Присоединяет сущность внутренним (`INNER`) объединением.
# 
# ## left_join ($field, $alias)
# 
# Присоединяет сущность левым (`LEFT`) объединением.
# 
# Оба метода разбирают описание через общий `_make_join` и поддерживают формы:
# 
# - `'user as u'` — поле `user` **главной** сущности, алиас `u`;
# - `user => 'u'` — то же; у алиаса отбрасывается ведущее `-` (`user => '-u'`);
# - `'u.admin as a'` — поле `admin` уже присоединённого алиаса `u`, алиас `a`;
# - `u__admin => 'a'` — то же в форме «алиас__поле => алиас».
# 
# Поле должно быть объявлено как `ref`; в `Join` кладётся модель-источник и её `ref`-поле. Имя таблицы и колонки для `ON` получает трансформер.
# 
::done_testing; }; subtest 'left_join ($field, $alias)' => sub { 
package Storage::Book::Join {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has id      => (is => 'ro', isa => Int, pk => 1, col => 1);
	has user    => (is => 'ro', isa => Object['Storage::User::Join'], ref => 1);
}

package Storage::User::Join {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'users';

	has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
	has name => (is => 'ro', isa => Str, col => 1);
}

my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Join');

my $joined = $qb->left_join('user as u');
my $join = $joined->_query->join->[0];

local ($::_g0 = do {$join->join}, $::_e0 = do {'left'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->join       # -> \'left\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$join->model}, $::_e0 = do {'Storage::Book::Join'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->model      # -> \'Storage::Book::Join\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$join->field}, $::_e0 = do {'user'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->field      # -> \'user\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$join->from_alias}, $::_e0 = do {'S'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->from_alias # -> \'S\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$join->to_alias}, $::_e0 = do {'u'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->to_alias   # -> \'u\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Новый алиас регистрируется, по нему можно присоединять дальше
local ($::_g0 = do {$joined->_aliases->{u}}, $::_e0 = do {'Storage::User::Join'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$joined->_aliases->{u} # -> \'Storage::User::Join\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Парная форма, тире отбрасывается
my $inner = $qb->inner_join(user => '-u');
local ($::_g0 = do {$inner->_query->join->[0]->to_alias}, $::_e0 = do {'u'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$inner->_query->join->[0]->to_alias # -> \'u\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$inner->_query->join->[0]->join}, $::_e0 = do {'inner'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$inner->_query->join->[0]->join     # -> \'inner\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Неизвестное поле
eval {$qb->inner_join('zzz as a')}; local ($::_g0 = $@, $::_e0 = 'Not zzz field'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '$qb->inner_join(\'zzz as a\') # @-> Not zzz field' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

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
