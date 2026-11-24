use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # # NAME
# 
# Aion::Aya::Query - запрос к базе (DQL): выборка, условия, соединения, сортировка и пагинация
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
package Storage::Book::Synopsis {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::Query;
use aliased 'Aion::Aya::Query::Join' => 'xJoin';

my $query = Aion::Aya::Query->new(
	from => 'Storage::Book::Synopsis',
	select => [],
	join => [xJoin->new(field => 'author', alias => 'a', join => 'left')],
	group_by => [],
	having => undef,
	order_by => [],
	offset => 20,
	limit => 10,
);

local ($::_g0 = do {$query->operation}, $::_e0 = do {'select'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->operation                   # -> \'select\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->from}, $::_e0 = do {'Storage::Book::Synopsis'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->from                        # -> \'Storage::Book::Synopsis\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar(@{$query->select})}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$query->select})           # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->join->[0]->{alias}}, $::_e0 = do {'a'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->join->[0]->{alias}          # -> \'a\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->join->[0]->{join}}, $::_e0 = do {'left'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->join->[0]->{join}           # -> \'left\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar(@{$query->group_by})}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$query->group_by})         # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->having}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->having                      # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar(@{$query->order_by})}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$query->order_by})         # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->offset}, $::_e0 = do {20}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->offset                      # -> 20' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->limit}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->limit                       # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->filter}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->filter                      # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# Обязателен только from; остальное по умолчанию пусто
my $empty = Aion::Aya::Query->new(from => 'Storage::Book::Synopsis');

local ($::_g0 = do {scalar(@{$empty->select})}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$empty->select})   # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar(@{$empty->join})}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$empty->join})     # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {scalar(@{$empty->order_by})}, $::_e0 = do {0}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'scalar(@{$empty->order_by}) # -> 0' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$empty->limit}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$empty->limit               # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

eval {Aion::Aya::Query->new}; local ($::_g0 = $@, $::_e0 = 'from required'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, 'Aion::Aya::Query->new # @-> from required' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Aya::Query` — объектное представление запроса. Модуль ничего не знает о базе: он только хранит части запроса. Запрос можно собрать, склонировать и дополнить, а затем передать адаптеру — тот отдаст `Aion::Aya::Iterator` или число затронутых строк.
# 
# Операция по умолчанию — `select`. Остальные операции (`insert`, `update`, `delete`) используются `Aion::Aya::Box` и `Aion::Aya::Appearance` при записи.
# 
# Обязателен только `from`; остальные части по умолчанию пусты.
# 
# # SUBROUTINES
# 
# ## clone ()
# 
# Создаёт независимую копию запроса: изменения в копии не затрагивают оригинал.
# 
::done_testing; }; subtest 'clone ()' => sub { 
package Storage::Book::Clone {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::Query;

my $query = Aion::Aya::Query->new(from => 'Storage::Book::Clone', limit => 10);

my $copy = $query->clone(limit => 25);

local ($::_g0 = do {ref $copy}, $::_e0 = do {'Aion::Aya::Query'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'ref $copy      # -> \'Aion::Aya::Query\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$copy->from}, $::_e0 = do {'Storage::Book::Clone'}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$copy->from    # -> \'Storage::Book::Clone\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->limit}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->limit  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$copy->limit}, $::_e0 = do {25}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$copy->limit   # -> 25' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

my $copy2 = $copy->clone(limit => 30);
local ($::_g0 = do {$copy2->limit}, $::_e0 = do {30}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$copy2->limit  # -> 30' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$copy->limit}, $::_e0 = do {25}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$copy->limit   # -> 25' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {$query->limit}, $::_e0 = do {10}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '$query->limit  # -> 10' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

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
# The Aion::Aya::Query module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
