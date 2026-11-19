use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Aya::Transaction - транзакция для Aion::Aya
# 
# # VERSION
# 
# 0.0.0
# 
# # SYNOPSIS
# 
# Файл etc/include.yml:
#@> etc/include.yml
#>> aion:
#>>   eon:
#>>     Aion::Aya::Adapter:
#>>       class: Aion::Aya::Adapter::MemAdapter
#>>     CHI:
#>>       class: CHI
#>>       arguments:
#>>         driver: None
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';
use aliased 'Liberia::Storage::Author::AuthorBox';

my $appearance = Appearance->new;

{
    my $tx = $appearance->transaction;

    my $author = Author->new(name => 'A.Rudazov');
    $appearance->persist($author)->flush;
    
    $tx->commit;
}

local ($::_g0 = do {AuthorBox->find_one_by_name('A.Rudazov')->id}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'AuthorBox->find_one_by_name(\'A.Rudazov\')->id # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

{
    my $tx = $appearance->transaction;

    my $author = Author->new(name => 'Zero');
    $appearance->persist($author)->flush;
    
    $tx->rollback;
}

local ($::_g0 = do {AuthorBox->find_one_by_name('Zero')}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'AuthorBox->find_one_by_name(\'Zero\') # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Aya::Transaction` — это транзакция базы данных, привязанная к текущему волокну (`Coro`). В одном волокне одновременно может быть только одна активная транзакция.
# 
# Транзакция объявляется у менеджера сущностей (`Aion::Aya::Appearance`). Пока она жива, все обращения к базе в текущем волокне (fiber) входят в неё. Её нужно завершить вызовом `commit` или `rollback`. Если переменная с транзакцией уйдёт из области видимости без `commit`, автоматически сработает `rollback`.
# 
# Транзакция связана со своим адаптером: при создании она вызывает у адаптера `begin_transaction($self)`, и адаптер запоминает её под адресом текущего волокна. Все соединения (`DBH`), которые будут открыты в этом волокне во время жизни транзакции, добавляются в неё — так что `commit`/`rollback` распространяется на всю работу внутри транзакции.
# 
# # STEP BY STEP
# 
# Открыть транзакцию:
# 
# 	my $tx = $appearance->transaction;
# 
# Выполнить нужную работу — например, сохранить несколько объектов (всё это происходит именно в пределах транзакции):
# 
# 	$appearance->persist($book)->flush;
# 
# Зафиксировать изменения, если всё прошло успешно:
# 
# 	$tx->commit;
# 
# Либо отменить изменения:
# 
# 	$tx->rollback;
# 
# # INIT
# 
# По умолчанию у `Aion::Aya::Appearance` подключён адаптер через контейнер эонов (`Aion::Pleroma`), например in‑memory драйвер. Транзакция использует именно адаптер менеджера сущностей, из которого была получена.
# 
# Дальше показаны две типовые сценария: **успешное сохранение** (с `commit`) и **откат** (с `rollback`).
# 
# Пусть есть сущность автора с первичным ключом и автоинкрементом:
# 
# Файл lib/Liberia/Storage/Author/Author.pm:
#@> lib/Liberia/Storage/Author/Author.pm
#>> package Liberia::Storage::Author::Author;
#>> use common::sense;
#>> use Aion::Aya;
#>> 
#>> # Authors of the Liberia
#>> presents 'authors';
#>> 
#>> # The identifier
#>> has id => (is => 'ro', isa => Nat, pk => 1, next => -identity);
#>> 
#>> # Name of the author
#>> has name => (is => 'ro', isa => NonEmptyStr, col => 1, unique => 1);
#>> 
#>> 1;
#@< EOF
# 
# И его репозиторий:
# 
# Файл lib/Liberia/Storage/Author/AuthorBox.pm:
#@> lib/Liberia/Storage/Author/AuthorBox.pm
#>> package Liberia::Storage::Author::AuthorBox;
#>> use common::sense;
#>> use Aion::Aya::Box;
#>> 
#>> for_box 'Liberia::Storage::Author::Author';
#>> 
#>> # Получить автора по имени
#>> sub find_one_by_name {
#>> 	my ($self, $name) = @_;
#>> 
#>> 	$self->query_builder->filter(name => $name)->first;
#>> }
#>> 
#>> 1;
#@< EOF
# 
# # METHODS
# 
# ## commit
# 
# Завершает транзакцию, фиксируя её (`commit` всех открытых соединений) и извлекая её из состояния адаптера.
# 
::done_testing; }; subtest 'commit' => sub { 
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

my $appearance = Appearance->new;
my $tx = $appearance->transaction;

my $author = Author->new(name => 'Tolstoy L.N.');
$appearance->persist($author)->flush;

$tx->commit;

local ($::_g0 = do {AuthorBox->find_one_by_name('Tolstoy L.N.')->id}, $::_e0 = do {3}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'AuthorBox->find_one_by_name(\'Tolstoy L.N.\')->id # -> 3' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## rollback
# 
# Завершает транзакцию, откатывая её (`rollback` всех открытых соединений).
# 
::done_testing; }; subtest 'rollback' => sub { 
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

my $appearance = Appearance->new;
my $tx = $appearance->transaction;

my $author = Author->new(name => 'Dostoevsky F.M.');
$appearance->persist($author)->flush;

$tx->rollback;

local ($::_g0 = do {AuthorBox->find_one_by_name('Dostoevsky F.M.')}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'AuthorBox->find_one_by_name(\'Dostoevsky F.M.\') # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # EXAMPLES
# 
# Если переменную, хранящую транзакцию, не закоммитить, то при уничтожении она вызовет `rollback`:
# 
::done_testing; }; subtest 'EXAMPLES' => sub { 
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

sub create_attempt {
	my ($appearance, $name) = @_;

	my $tx = $appearance->transaction;
	my $author = Author->new(name => $name);
	$appearance->persist($author)->flush;
}

my $appearance = Appearance->new;
create_attempt($appearance, 'Chekhov A.P.');

local ($::_g0 = do {AuthorBox->find_one_by_name('Chekhov A.P.')}, $::_e0 = do {undef}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, 'AuthorBox->find_one_by_name(\'Chekhov A.P.\') # -> undef' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# Транзакция открытая в внутри другой вызовет исключение:
# 

{
    my $tx = $appearance->transaction;

eval {$appearance->transaction}; local ($::_g0 = $@, $::_e0 = 'Transaction beginned!'); ok defined($::_g0) && $::_g0 =~ /^${\quotemeta $::_e0}/, '    $appearance->transaction # @-> Transaction beginned!' or ::diag ::_string_diff($::_g0, $::_e0, 1); undef $::_g0; undef $::_e0;

    $tx->rollback;
}

# 
# # GOTCHAS
# 
# * Транзакция привязана к текущему волокну; не переносите её в другое волокно.
# * В одном волокне единовременно открыта только одна транзакция — вторая попытка `begin_transaction` для того же волокна вызовет исключение.
# * Завершать транзакцию стоит явно (`commit`/`rollback`); полагаться на автоматический откат при выходе из области видимости допустимо, но лучше не затягивать транзакцию.
# 
# # SUBROUTINES
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
# The Aion::Aya module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
