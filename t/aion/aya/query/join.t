use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-4]); 	my $project_name = $dirs[$#dirs-4]; 	my @test_dirs = @dirs[$#dirs-4+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Aya::Query::Join - соединение с другой таблицей
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
package Storage::Book::Join {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'books';

	has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
	has user => (is => 'ro', isa => Object['Storage::User::Join'], ref => 1);
}

package Storage::User::Join {
	use Aion with => 'Aion::Aya';
	use Aion::Types;

	presents 'users';

	has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
	has name => (is => 'ro', isa => Str, col => 1);
}

use aliased 'Aion::Aya::Query::Join' => 'xJoin';

my $join = xJoin->new(
	join => 'left',
	model => 'Storage::Book::Join',
	field => 'user',
	from_alias => 'b',
	to_alias => 'u',
);

local ($::_g0 = do {$join->join}, $::_e0 = do {'left'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->join       # -> \'left\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$join->model}, $::_e0 = do {'Storage::Book::Join'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->model      # -> \'Storage::Book::Join\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$join->field}, $::_e0 = do {'user'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->field      # -> \'user\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$join->from_alias}, $::_e0 = do {'b'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->from_alias # -> \'b\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$join->to_alias}, $::_e0 = do {'u'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$join->to_alias   # -> \'u\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $inner = xJoin->new(join => 'inner', model => 'Storage::Book::Join', field => 'user', from_alias => 'b', to_alias => 'u');

local ($::_g0 = do {$inner->join}, $::_e0 = do {'inner'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$inner->join # -> \'inner\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Тип соединения ограничен inner и left
eval {xJoin->new(join => 'outer', model => 'Storage::Book::Join', field => 'user', from_alias => 'b', to_alias => 'u')}; local ($::_g0 = $@, $::_e0 = 'Set feature join must have the type'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'xJoin->new(join => \'outer\', model => \'Storage::Book::Join\', field => \'user\', from_alias => \'b\', to_alias => \'u\') # @-> Set feature join must have the type' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Join` описывает одно соединение в `SELECT`. Список соединений хранит `Aion::Aya::Query` в фиче `join`.
# 
# `Join` — чистые данные: никакого SQL здесь нет. Как именно выглядит соединение, решает трансформер (SQL, Elastic и т. п.). Из этих данных можно собрать, например, `LEFT JOIN users u ON u.id = b.user_id`:
# 
# - `model` — класс модели-источника, у которой есть `ref`-поле `field` (здесь `Storage::Book::Join::user`);
# - `field` — имя этого `ref`-поля;
# - `from_alias` — псевдоним таблицы-источника в текущем запросе (`b`);
# - `to_alias` — псевдоним присоединяемой таблицы (`u`);
# - `join` — тип соединения (`inner` или `left`).
# 
# Результирующая модель получается из источника: `Model->get_ref(Model->get($join->model)->feature($join->field))`. Имя таблицы и имена колонок для `ON` также получает трансформер.
# 
# Класс подключается через `aliased` под именем `xJoin`: `Join` — ещё и тип-функция в `Aion::Types`, и в пакете с `use Aion` голое `Join->new` распознаётся как вызов прототипа.
# 
# Тип соединения ограничен значениями `inner` и `left`; любое другое бросает исключение в конструкторе.
# 
# # FEATURES
# 
# ## join
# 
# Тип соединения: `inner` или `left`.
# 
# ## model
# 
# Класс модели-источника, чьё `ref`-поле участвует в соединении.
# 
# ## field
# 
# Имя `ref`-поля в модели `model`. По нему определяется результирующая модель и колонка источника.
# 
# ## from_alias
# 
# Псевдоним таблицы-источника в текущем запросе.
# 
# ## to_alias
# 
# Псевдоним присоединяемой таблицы.
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
# The Aion::Aya::Query::Join module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
