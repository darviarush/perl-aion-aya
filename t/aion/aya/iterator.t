use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Aya::Iterator - курсор по строкам результата запроса с перегрузками для удобного перебора
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
package Adapter::Mock {
	our @ISA = 'Aion::Aya::Adapter';

	sub new { bless {}, shift }

	sub next { my ($self, $session) = @_; $session->{rows}[$session->{i}++] }
}

use Aion::Aya::Iterator;

Aion::Aya::Iterator->Aion::initialize;

my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [1, 2, 3]});

local ($::_g0 = do {$iterator->next}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$iterator->next}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$iterator->next}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$iterator->next}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Aya::Iterator` — тонкая обёртка над **сессией** адаптера. Сам итератор ничего не знает о базе: он хранит `adapter` и `session`, а всю работу делает адаптер.
# 
# `session` для адаптера на `DBI` (`Aion::Aya::Adapter::Iterator::DBI`) — это хеш, который адаптер наполняет лениво, по мере вызовов `next`:
# 
# - `query` — объект `Aion::Aya::Query`, из которого трансформатор делает SQL (для `iterator`);
# - `sql` — готовый SQL (для `raw_iterator`);
# - `dbh` — соединение, берётся из пула адаптера или открывается заново;
# - `sth` — подготовленный и запущенный запрос; когда строки кончились, `sth` и `dbh` из сессии удаляются и возвращаются в пул.
# 
# Поэтому итератор — это **одноразовый курсор**: сессия продвигается вперёд, а вернуться к уже прочитанным строкам нельзя.
# 
# `Iterator` перегружает три операции:
# 
# - **`@{ }`** — собрать все оставшиеся строки в массив;
# - **`&{ }`** — получить функцию-генератор, которая при каждом вызове отдаёт `next`;
# - **`< >`** — это `next` (в скалярном контексте).
# 
# Объекты, которые отдаёт итератор, зависят от источника:
# 
# - для `iterator` адаптер создаёт сущность класса `$query->from` — **или** прокси-наследника, если в строке есть поля-алиасы, которых у сущности нет (см. `Aion::Aya::Adapter`);
# - для `raw_iterator` отдаётся «сырая» строка — `HashRef` с именами колонок.
# 
# # FEATURES
# 
# ## adapter
# 
# Обязательный адаптер. Требование ослабленное (`is => 'ro*'`), то есть итератор держит **слабую** ссылку на адаптер: адаптер должен жить отдельно, иначе он исчезнет и `next` упадёт.
# 
# ## session
# 
# Сессия итератора. Даёт доступ к тому же состоянию запроса, по которому идут строки: `dbh`, `sth` и исходный `query`/`sql`. Итератор передаёт её в `adapter->next`, поэтому она же является единицей состояния и для протокола адаптера.
# 
# # METHODS
# 
# ## next
# 
# Возвращает следующую строку через `$self->{adapter}->next($self->{session})` или `undef`, когда строки закончились.
# 
# Это тот метод, который вызывают все перегрузки; реализует его адаптер.
# 
::done_testing; }; subtest 'next' => sub { 
my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['one', 'two', 'three']});

my $first = $iterator->next;
local ($::_g0 = do {$first}, $::_e0 = do {'one'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$first              # -> \'one\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$iterator->next}, $::_e0 = do {'two'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next     # -> \'two\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$iterator->next}, $::_e0 = do {'three'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next     # -> \'three\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$iterator->next}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next     # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # EXAMPLES
# 
# ## next
# 

my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [1, 2, 3]});

my @values;
while(my $value = $iterator->next) { push @values, $value }

local ($::_g0 = do {"@values"}, $::_e0 = do {"1 2 3"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"@values"       # -> "1 2 3"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {$iterator->next}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$iterator->next}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$iterator->next # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## @{ }
# 
::done_testing; }; subtest '@{ }' => sub { 
my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['a', 'b', 'c']});

my $rows = \@$iterator;

local ($::_g0 = do {ref $rows}, $::_e0 = do {'ARRAY'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $rows           # -> \'ARRAY\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar @$rows}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar @$rows       # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {"@$rows"}, $::_e0 = do {"a b c"}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '"@$rows"            # -> "a b c"' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {scalar @{$iterator}}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar @{$iterator} # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## &{ }
# 
::done_testing; }; subtest '&{ }' => sub { 
my $adapter = Adapter::Mock->new;
my $generator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [10, 20, 30]});

local ($::_g0 = do {$generator->()}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$generator->()   # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$generator->()}, $::_e0 = do {20}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$generator->()   # -> 20' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$generator->()}, $::_e0 = do {30}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$generator->()   # -> 30' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$generator->()}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$generator->()   # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {ref $generator}, $::_e0 = do {'Aion::Aya::Iterator'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $generator   # -> \'Aion::Aya::Iterator\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## < >
# 
::done_testing; }; subtest '< >' => sub { 
my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['x', 'y']});

my $first = <$iterator>;
local ($::_g0 = do {$first}, $::_e0 = do {'x'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$first           # -> \'x\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {<$iterator>}, $::_e0 = do {'y'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '<$iterator>      # -> \'y\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {<$iterator>}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '<$iterator>      # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
# The Aion::Aya::Iterator module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
