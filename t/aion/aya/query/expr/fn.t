use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-5]); 	my $project_name = $dirs[$#dirs-5]; 	my @test_dirs = @dirs[$#dirs-5+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Aya::Query::Expr::Fn - вызов функции базы в выражении
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Aya::Query::Expr::Val;
use Aion::Aya::Query::Expr::Fn;

my $arg = Aion::Aya::Query::Expr::Val->new(value => 'title');

my $fn = Aion::Aya::Query::Expr::Fn->new(name => 'COUNT', args => [$arg]);

local ($::_g0 = do {$fn->name}, $::_e0 = do {'COUNT'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$fn->name           # -> \'COUNT\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$fn->args->[0]->value}, $::_e0 = do {'title'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$fn->args->[0]->value # -> \'title\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$fn->isa('Aion::Aya::Query::Expr')}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$fn->isa(\'Aion::Aya::Query::Expr\') # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Несколько аргументов
my $coalesce = Aion::Aya::Query::Expr::Fn->new(
	name => 'COALESCE',
	args => [
		Aion::Aya::Query::Expr::Val->new(value => 1),
		Aion::Aya::Query::Expr::Val->new(value => 0),
	],
);

local ($::_g0 = do {scalar(@{$coalesce->args})}, $::_e0 = do {2}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$coalesce->args}) # -> 2' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Пустой список аргументов допустим
my $now = Aion::Aya::Query::Expr::Fn->new(name => 'NOW', args => []);

local ($::_g0 = do {scalar(@{$now->args})}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$now->args}) # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# Узел дерева выражений для вызова функции базы: `name(args...)`. Аргументы — любые выражения (`Val`, `Field`, другие `Fn`), список может быть пустым.
# 
# # FEATURES
# 
# ## name
# 
# Имя функции базы (`COUNT`, `COALESCE`, `LOWER`).
# 
# ## args
# 
# Список аргументов — выражений.
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
# The Aion::Aya::Query::Expr::Fn module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
