use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-3]); 	my $project_name = $dirs[$#dirs-3]; 	my @test_dirs = @dirs[$#dirs-3+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # 
# # NAME
# 
# Aion::Aya::Types - типы для колонок базы (целые по ширине, деньги, строки, блобы, сущности)
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Aya::Types;

local ($::_g0 = do {1 ~~ TinyNat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ TinyNat          # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-1 ~~ TinyNat}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-1 ~~ TinyNat         # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {256 ~~ TinyNat}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '256 ~~ TinyNat        # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

local ($::_g0 = do {'Привет' ~~ TinyText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Привет\' ~~ TinyText  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {1 ~~ PositiveTinyInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ PositiveTinyInt  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# # DESCRIPTION
# 
# `Aion::Aya::Types` — набор подтипов для описания колонок таблиц в духе типов MySQL. Модуль делает две вещи:
# 
# 1. **Переэкспортирует типы.** `@EXPORT` собирается из функций `Aion::Aya::Types` (заодно подтягиваются и базовые типы `Aion::Types`), поэтому после `use Aion::Aya::Types` все они доступны в вызывающем пакете по короткому имени: `TinyNat`, `Money`, `TinyText` и т. д.
# 2. **Объявляет свои подтипы** через `subtype` из `Aion::Types`.
# 
# Базой для «целых» служат `Bytes[n]` и `PositiveBytes[n]`: это диапазоны в `n` байт. `PositiveBytes[n]` покрывает `0..2^(8n)-1`, `Bytes[n]` — знаковый `-2^(8n-1)..2^(8n-1)-1`.
# 
# Проверка — это стандартная `~~`: `VALUE ~~ Тип` даёт `1`, если значение подходит, и `''`, если нет. Тип-функцию передают без скобок; параметризованные — `Char[4]`, `Decimal[10,2]`.
# 
# # TYPES
# 
# ## PositiveTinyInt
# 
# Беззнаковое целое в 1 байт: `0..255`.
# 
::done_testing; }; subtest 'PositiveTinyInt' => sub { 
local ($::_g0 = do {255 ~~ PositiveTinyInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '255 ~~ PositiveTinyInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {256 ~~ PositiveTinyInt}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '256 ~~ PositiveTinyInt # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## PositiveShortInt
# 
# Беззнаковое целое в 2 байта: `0..65535`.
# 
::done_testing; }; subtest 'PositiveShortInt' => sub { 
local ($::_g0 = do {65535 ~~ PositiveShortInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '65535 ~~ PositiveShortInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {0 ~~ PositiveShortInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '0 ~~ PositiveShortInt     # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## PositiveMediumInt
# 
# Беззнаковое целое в 3 байта: `0..16777215`.
# 
::done_testing; }; subtest 'PositiveMediumInt' => sub { 
local ($::_g0 = do {16777215 ~~ PositiveMediumInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '16777215 ~~ PositiveMediumInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## PositiveLongInt
# 
# Беззнаковое целое в 4 байта: `0..4294967295`.
# 
::done_testing; }; subtest 'PositiveLongInt' => sub { 
local ($::_g0 = do {4294967295 ~~ PositiveLongInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '4294967295 ~~ PositiveLongInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## PositiveBigInt
# 
# Беззнаковое целое в 8 байт: `0..2^64-1`.
# 
::done_testing; }; subtest 'PositiveBigInt' => sub { 
local ($::_g0 = do {1 ~~ PositiveBigInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ PositiveBigInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-1 ~~ PositiveBigInt}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-1 ~~ PositiveBigInt # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## TinyInt
# 
# Знаковое целое в 1 байт: `-128..127`.
# 
::done_testing; }; subtest 'TinyInt' => sub { 
local ($::_g0 = do {-128 ~~ TinyInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-128 ~~ TinyInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {127 ~~ TinyInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '127 ~~ TinyInt  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {128 ~~ TinyInt}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '128 ~~ TinyInt  # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ShortInt
# 
# Знаковое целое в 2 байта: `-32768..32767`.
# 
::done_testing; }; subtest 'ShortInt' => sub { 
local ($::_g0 = do {32767 ~~ ShortInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '32767 ~~ ShortInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {32768 ~~ ShortInt}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '32768 ~~ ShortInt # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## MediumInt
# 
# Знаковое целое в 3 байта: `-8388608..8388607`.
# 
::done_testing; }; subtest 'MediumInt' => sub { 
local ($::_g0 = do {8388607 ~~ MediumInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '8388607 ~~ MediumInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## LongInt
# 
# Знаковое целое в 4 байта: `-2147483648..2147483647`.
# 
::done_testing; }; subtest 'LongInt' => sub { 
local ($::_g0 = do {2147483647 ~~ LongInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '2147483647 ~~ LongInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## BigInt
# 
# Знаковое целое в 8 байт.
# 
::done_testing; }; subtest 'BigInt' => sub { 
local ($::_g0 = do {5 ~~ BigInt}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '5 ~~ BigInt # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## TinyNat
# 
# Неотрицательное целое в 1 байт: `Nat & PositiveBytes[1]`, то есть `0..255`.
# 
::done_testing; }; subtest 'TinyNat' => sub { 
local ($::_g0 = do {1 ~~ TinyNat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ TinyNat  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-1 ~~ TinyNat}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-1 ~~ TinyNat # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ShortNat
# 
# `Nat & PositiveBytes[2]`: `0..65535`.
# 
::done_testing; }; subtest 'ShortNat' => sub { 
local ($::_g0 = do {65535 ~~ ShortNat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '65535 ~~ ShortNat # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## MediumNat
# 
# `Nat & PositiveBytes[3]`: `0..16777215`.
# 
::done_testing; }; subtest 'MediumNat' => sub { 
local ($::_g0 = do {16777215 ~~ MediumNat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '16777215 ~~ MediumNat # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## LongNat
# 
# `Nat & PositiveBytes[4]`: `0..4294967295`.
# 
::done_testing; }; subtest 'LongNat' => sub { 
local ($::_g0 = do {4294967295 ~~ LongNat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '4294967295 ~~ LongNat # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## BigNat
# 
# `Nat & PositiveBytes[8]`.
# 
::done_testing; }; subtest 'BigNat' => sub { 
local ($::_g0 = do {1 ~~ BigNat}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '1 ~~ BigNat # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Money
# 
# Денежное значение: `Range[-92233720368547758.08, +92233720368547758.07]`.
# 
::done_testing; }; subtest 'Money' => sub { 
local ($::_g0 = do {100 ~~ Money}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '100 ~~ Money   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {12.5 ~~ Money}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '12.5 ~~ Money  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Decimal[A, B]
# 
# Число с не более чем `A - B` цифрами до точки и дробной частью.
# 
::done_testing; }; subtest 'Decimal[A, B]' => sub { 
local ($::_g0 = do {12.34 ~~ Decimal[10,2]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '12.34 ~~ Decimal[10,2]    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {-12.34 ~~ Decimal[10,2]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '-12.34 ~~ Decimal[10,2]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {12345678.9 ~~ Decimal[10,2]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '12345678.9 ~~ Decimal[10,2] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {123456789.1 ~~ Decimal[10,2]}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '123456789.1 ~~ Decimal[10,2] # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Binary[A]
# 
# Двоичная строка длины не более `A` байт.
# 
::done_testing; }; subtest 'Binary[A]' => sub { 
local ($::_g0 = do {'abcd' ~~ Binary[4]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abcd\' ~~ Binary[4]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'abcde' ~~ Binary[4]}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abcde\' ~~ Binary[4] # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Varbinary[A]
# 
# Двоичная строка переменной длины не более `A` байт: `Bin & Len[A]`.
# 
::done_testing; }; subtest 'Varbinary[A]' => sub { 
local ($::_g0 = do {'ab' ~~ Varbinary[2]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'ab\' ~~ Varbinary[2]   # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'abc' ~~ Varbinary[2]}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abc\' ~~ Varbinary[2]  # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Char[A]
# 
# Unicode-строка длины не более `A` символов: `Uni & Len[A]`.
# 
::done_testing; }; subtest 'Char[A]' => sub { 
local ($::_g0 = do {'abc' ~~ Char[3]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abc\' ~~ Char[3]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'я' ~~ Char[1]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'я\' ~~ Char[1]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'яя' ~~ Char[1]}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'яя\' ~~ Char[1] # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Varchar[A]
# 
# Unicode-строка переменной длины не более `A` символов: `Uni & Len[A]`.
# 
::done_testing; }; subtest 'Varchar[A]' => sub { 
local ($::_g0 = do {'abc' ~~ Varchar[5]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abc\' ~~ Varchar[5] # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'аб' ~~ Varchar[2]}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'аб\' ~~ Varchar[2]  # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'абв' ~~ Varchar[2]}, $::_e0 = do {''}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'абв\' ~~ Varchar[2] # -> \'\'' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## TinyText
# 
# Unicode-строка до 255 символов: `Uni & Len[255]`.
# 
::done_testing; }; subtest 'TinyText' => sub { 
local ($::_g0 = do {'abc' ~~ TinyText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abc\' ~~ TinyText    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'Привет' ~~ TinyText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Привет\' ~~ TinyText # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ShortText
# 
# Unicode-строка до 65535 символов: `Uni & Len[65_535]`.
# 
::done_testing; }; subtest 'ShortText' => sub { 
local ($::_g0 = do {'abc' ~~ ShortText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abc\' ~~ ShortText    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'Привет' ~~ ShortText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Привет\' ~~ ShortText # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## MediumText
# 
# Unicode-строка до 16777215 символов: `Uni & Len[16_777_215]`.
# 
::done_testing; }; subtest 'MediumText' => sub { 
local ($::_g0 = do {'abc' ~~ MediumText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abc\' ~~ MediumText    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'Привет' ~~ MediumText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Привет\' ~~ MediumText # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## LongText
# 
# Unicode-строка до 4294967295 символов: `Uni & Len[4_294_967_295]`.
# 
::done_testing; }; subtest 'LongText' => sub { 
local ($::_g0 = do {'abc' ~~ LongText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'abc\' ~~ LongText    # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;
local ($::_g0 = do {'Привет' ~~ LongText}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'Привет\' ~~ LongText # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## TinyBlob
# 
# Бинарные данные до 255 байт: `Bin & Len[255]`.
# 
::done_testing; }; subtest 'TinyBlob' => sub { 
local ($::_g0 = do {'bytes' ~~ TinyBlob}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'bytes\' ~~ TinyBlob # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## ShortBlob
# 
# Бинарные данные до 65535 байт: `Bin & Len[65_535]`.
# 
::done_testing; }; subtest 'ShortBlob' => sub { 
local ($::_g0 = do {'bytes' ~~ ShortBlob}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'bytes\' ~~ ShortBlob # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## MediumBlob
# 
# Бинарные данные до 16777215 байт: `Bin & Len[16_777_215]`.
# 
::done_testing; }; subtest 'MediumBlob' => sub { 
local ($::_g0 = do {'bytes' ~~ MediumBlob}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'bytes\' ~~ MediumBlob # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## LongBlob
# 
# Бинарные данные до 4294967295 байт: `Bin & Len[4_294_967_295]`.
# 
::done_testing; }; subtest 'LongBlob' => sub { 
local ($::_g0 = do {'bytes' ~~ LongBlob}, $::_e0 = do {1}); ::ok defined($::_g0) == defined($::_e0) && $::_g0 eq $::_e0, '\'bytes\' ~~ LongBlob # -> 1' or ::diag ::_struct_diff($::_g0, $::_e0); undef $::_g0; undef $::_e0;

# 
# ## Entity[class, appearance_key?]
# 
# Тип-сущность: `Object[class]`, который умеет приводиться из строки-идентификатора через `coerce`. Для `Str` он берёт `Appearance` (по умолчанию `Aion::Aya::Appearance`), находит первичный ключ модели и ищет объект по нему; если не нашёл — оставляет строку как есть.
# 
# Используется в `has … isa => Entity[...]`, чтобы можно было передать id вместо объекта. Пример здесь не приводится: конструктору нужен рабочий `Aion::Aya::Appearance` с базой, а библиотека ещё не дописана.
# 
# # GOTCHAS
# 
# * **`Entity` требует рабочего `Appearance`.** Приведение `Str → объект` идёт через `Aion->pleroma->resolve('Aion::Aya::Appearance')` и `QueryBuilder`, поэтому в отрыве от базы/`Appearance` тип не работает.
# 
# # NOMENCLATURE
# 
# В объявлении `subtype "Имя[A, b]", …` имена параметров имеют значение:
# 
# * **Одна заглавная буква** (`A`, `B`, …) — параметр является объектом `Aion::Type` (самим типом), а не значением. С ним работают как с типом: `A->test`, `A->include($val)`.
# * **Строчные имена** (`n`, `from`, `to`, `a`, `b`) — обычные значения, с ними можно делать арифметику и подставлять их в строки/regexp.
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
# The Aion::Aya::Types module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

	::done_testing;
};

::done_testing;
