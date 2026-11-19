use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-4]); 	my $project_name = $dirs[$#dirs-4]; 	my @test_dirs = @dirs[$#dirs-4+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Aya::Query::Expr - выражение запроса и перегрузки операторов для его сборки
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Aya::Query::Expr::Val;
use Aion::Aya::Query::Expr::Field;

package Storage::Book::Expr {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

my $title = Aion::Aya::Query::Expr::Field->new(alias => 'b', name => 'title', entity => 'Storage::Book::Expr');

# Арифметика: литерал справа становится Val
my $sum = $title + 1;
local ($::_g0 = do {ref $sum}, $::_e0 = do {'Aion::Aya::Query::Expr::Op'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $sum              # -> \'Aion::Aya::Query::Expr::Op\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$sum->op}, $::_e0 = do {'+'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sum->op              # -> \'+\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$sum->left->name}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sum->left->name      # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$sum->right->value}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sum->right->value    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Сравнение
my $eq = $title == 'Clarissa';
local ($::_g0 = do {$eq->op}, $::_e0 = do {'='}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$eq->op               # -> \'=\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$eq->right->value}, $::_e0 = do {'Clarissa'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$eq->right->value     # -> \'Clarissa\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Унарные операции
my $neg = -$sum;
local ($::_g0 = do {ref $neg}, $::_e0 = do {'Aion::Aya::Query::Expr::UOp'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $neg              # -> \'Aion::Aya::Query::Expr::UOp\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$neg->op}, $::_e0 = do {'-'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$neg->op              # -> \'-\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $not = ~$eq;
local ($::_g0 = do {$not->op}, $::_e0 = do {'NOT'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$not->op              # -> \'NOT\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Логика
my $and = $eq & $neg;
local ($::_g0 = do {$and->op}, $::_e0 = do {'AND'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$and->op              # -> \'AND\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $or = $eq | $neg;
local ($::_g0 = do {$or->op}, $::_e0 = do {'OR'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$or->op               # -> \'OR\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Expr справа: операнды меняются местами
my $sub = 10 - $sum;
local ($::_g0 = do {$sub->op}, $::_e0 = do {'-'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sub->op              # -> \'-\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$sub->left->value}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sub->left->value     # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$sub->right->op}, $::_e0 = do {'+'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$sub->right->op       # -> \'+\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Expr` — роль, общая для всех узлов дерева выражений: `Val`, `Field`, `Fn`, `Op`, `UOp`. Сама по себе не инстанцируется.
# 
# Главная ценность роли — `overload`: любой узел можно собирать обычными перлами вместо ручного построения `Op`/`UOp`. Справа может стоять что угодно: если это не `Expr`, значение оборачивается в `Val` автоматически.
# 
# | Perl | В дереве | Узел |
# |---|---|---|
# | `$a + $b` | `a + b` | `Op` |
# | `$a - $b` | `a - b` | `Op` |
# | `$a * $b` | `a * b` | `Op` |
# | `$a / $b` | `a / b` | `Op` |
# | `$a % $b` | `a % b` | `Op` |
# | `$a ** $b` | `a ** b` | `Op` |
# | `$a == $b` | `a = b` | `Op` |
# | `$a != $b` | `a != b` | `Op` |
# | `$a < $b` | `a < b` | `Op` |
# | `$a > $b` | `a > b` | `Op` |
# | `$a <= $b` | `a <= b` | `Op` |
# | `$a >= $b` | `a >= b` | `Op` |
# | `$a . $b` | `a \|\| b` | `Op` |
# | `$a & $b` | `a AND b` | `Op` |
# | `$a \| $b` | `a OR b` | `Op` |
# | `-$a` | `- a` | `UOp` |
# | `~$a` | `NOT a` | `UOp` |
# 
# Порядок операндов учитывается: если `Expr` стоит справа (`10 - $v`), `overload` вызывает обработчик с признаком `swap`, и операнды меняются местами.
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
# The Aion::Aya::Query::Expr module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
