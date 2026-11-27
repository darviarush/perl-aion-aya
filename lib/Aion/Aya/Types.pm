package Aion::Aya::Types;
# Типы для базы

use common::sense;

use Aion::Aya::QueryBuilder;
use Aion::Aya::Model;
use Aion::Types;
use Exporter qw/import/;

our @EXPORT = our @EXPORT_OK = grep {
	eval { *{$Aion::Aya::Types::{$_}}{CODE} } && !/^(_|(NaN|import)\z)/n
} keys %Aion::Aya::Types::;

BEGIN {
#@category Валидаторы с запросами

	subtype "Entity[class, appearance_key?]", as Object[A],
		message { "Not exists ${\A()}<$_> in base" };

	# Конвертирует id в объект
	coerce &Entity, from Str, via {
		my $appearance = Aion->pleroma->resolve(B // 'Aion::Aya::Appearance');

		my $pkey = Aion::Aya::Model->get(A)->{primary_key};
		my $pk = $pkey->{fields}[0];

		my $qb = Aion::Aya::QueryBuilder->new(
			_appearance => $appearance,
			_from => A,
		)->filter($pk => $_);
	
		$qb->first // $_
	};

#@category Простые валидаторы
	
	subtype "PositiveTinyInt", as PositiveBytes[1];
	subtype "PositiveShortInt", as PositiveBytes[2];
	subtype "PositiveMediumInt", as PositiveBytes[3];
	subtype "PositiveLongInt", as PositiveBytes[4];
	subtype "PositiveBigInt", as PositiveBytes[8];

	subtype "TinyInt", as Bytes[1];
	subtype "ShortInt", as Bytes[2];
	subtype "MediumInt", as Bytes[3];
	subtype "LongInt", as Bytes[4];
	subtype "BigInt", as Bytes[8];

	subtype "TinyNat", as Nat & PositiveBytes[1];
	subtype "ShortNat", as Nat & PositiveBytes[2];
	subtype "MediumNat", as Nat & PositiveBytes[3];
	subtype "LongNat", as Nat & PositiveBytes[4];
	subtype "BigNat", as Nat & PositiveBytes[8];

	subtype "Money", as Range[-92233720368547758.08, +92233720368547758.07];
	subtype "Decimal[n, m]", as Num, where { /^-?\d{0,${\(A - B)}}(?:\.\d+)?\z/ };

	subtype "Binary[n]",    as Bin & Len[A];
	subtype "Varbinary[n]", as Bin & Len[A];
	subtype "Char[n]",      as Uni & Len[A];
	subtype "Varchar[n]",   as Uni & Len[A];

	subtype "TinyText",   as Uni & Len[255];
	subtype "ShortText",  as Uni & Len[65_535];
	subtype "MediumText", as Uni & Len[16_777_215];
	subtype "LongText",   as Uni & Len[4_294_967_295];

	subtype "TinyBlob",   as Bin & Len[255];
	subtype "ShortBlob",  as Bin & Len[65_535];
	subtype "MediumBlob", as Bin & Len[16_777_215];
	subtype "LongBlob",   as Bin & Len[4_294_967_295];

}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Types - types for base columns (width integers, money, strings, blobs, entities)

=head1 SYNOPSIS

	use Aion::Aya::Types;
	
	1 ~~ TinyNat          # -> 1
	-1 ~~ TinyNat         # -> ''
	256 ~~ TinyNat        # -> ''
	
	'Привет' ~~ TinyText  # -> 1
	1 ~~ PositiveTinyInt  # -> 1

=head1 DESCRIPTION

C<Aion::Aya::Types> - a set of subtypes for describing table columns in the spirit of MySQL types. The module does two things:

=over

=item 1. B<Re-exports types.> C<@EXPORT> is assembled from the C<Aion::Aya::Types> functions (at the same time the base types C<Aion::Types> are also pulled up), so after C<use Aion::Aya::Types> they are all available in the calling package by a short name: C<TinyNat>, C<Money>, C<TinyText>, etc.

=item 2. B<Declares its subtypes> using C<subtype> from C<Aion::Types>.

=back

The base for "integers" is C<Bytes[n]> and C<PositiveBytes[n]>: these are ranges of C<n> bytes. C<PositiveBytes[n]> covers C<0..2^(8n)-1>, C<Bytes[n]> covers signed C<-2^(8n-1)..2^(8n-1)-1>.

The check is the standard C<~~>: C<VALUE ~~ Type> gives C<1> if the value matches, and C<''> if it doesn't. The type function is passed without parentheses; parameterized - C<Char[4]>, C<Decimal[10,2]>.

=head1 TYPES

=head2 PositiveTinyInt

Unsigned integer of 1 byte: C<0..255>.

	255 ~~ PositiveTinyInt # -> 1
	256 ~~ PositiveTinyInt # -> ''

=head2 PositiveShortInt

Unsigned integer of 2 bytes: C<0..65535>.

	65535 ~~ PositiveShortInt # -> 1
	0 ~~ PositiveShortInt     # -> 1

=head2 PositiveMediumInt

Unsigned integer of 3 bytes: C<0..16777215>.

	16777215 ~~ PositiveMediumInt # -> 1

=head2 PositiveLongInt

Unsigned 4-byte integer: C<0..4294967295>.

	4294967295 ~~ PositiveLongInt # -> 1

=head2 PositiveBigInt

Unsigned integer of 8 bytes: C<0..2^64-1>.

	1 ~~ PositiveBigInt # -> 1
	-1 ~~ PositiveBigInt # -> ''

=head2 TinyInt

Signed integer of 1 byte: C<-128..127>.

	-128 ~~ TinyInt # -> 1
	127 ~~ TinyInt  # -> 1
	128 ~~ TinyInt  # -> ''

=head2 ShortInt

Signed integer of 2 bytes: C<-32768..32767>.

	32767 ~~ ShortInt # -> 1
	32768 ~~ ShortInt # -> ''

=head2 MediumInt

Signed integer of 3 bytes: C<-8388608..8388607>.

	8388607 ~~ MediumInt # -> 1

=head2 LongInt

Signed integer of 4 bytes: C<-2147483648..2147483647>.

	2147483647 ~~ LongInt # -> 1

=head2 BigInt

Signed integer of 8 bytes.

	5 ~~ BigInt # -> 1

=head2 TinyNat

Non-negative integer of 1 byte: C<Nat & PositiveBytes[1]>, that is C<0..255>.

	1 ~~ TinyNat  # -> 1
	-1 ~~ TinyNat # -> ''

=head2 ShortNat

C<Nat & PositiveBytes[2]>: C<0..65535>.

	65535 ~~ ShortNat # -> 1

=head2 MediumNat

C<Nat & PositiveBytes[3]>: C<0..16777215>.

	16777215 ~~ MediumNat # -> 1

=head2 LongNat

C<Nat & PositiveBytes[4]>: C<0..4294967295>.

	4294967295 ~~ LongNat # -> 1

=head2 BigNat

C<Nat & PositiveBytes[8]>.

	1 ~~ BigNat # -> 1

=head2 Money

Monetary value: C<Range[-92233720368547758.08, +92233720368547758.07]>.

	100 ~~ Money   # -> 1
	12.5 ~~ Money  # -> 1

=head2 Decimal[A, B]

A number with no more than C<A - B> digits before the dot and a fractional part.

	12.34 ~~ Decimal[10,2]    # -> 1
	-12.34 ~~ Decimal[10,2]   # -> 1
	12345678.9 ~~ Decimal[10,2] # -> 1
	123456789.1 ~~ Decimal[10,2] # -> ''

=head2 Binary[A]

A binary string of length no more than C<A> bytes.

	'abcd' ~~ Binary[4]  # -> 1
	'abcde' ~~ Binary[4] # -> ''

=head2 Varbinary[A]

Variable-length binary string no more than C<A> bytes: C<Bin & Len[A]>.

	'ab' ~~ Varbinary[2]   # -> 1
	'abc' ~~ Varbinary[2]  # -> ''

=head2 Char[A]

Unicode string of length no more than C<A> characters: C<Uni & Len[A]>.

	'abc' ~~ Char[3]  # -> 1
	'я' ~~ Char[1]  # -> 1
	'яя' ~~ Char[1] # -> ''

=head2 Varchar[A]

Variable-length Unicode string of no more than C<A> characters: C<Uni & Len[A]>.

	'abc' ~~ Varchar[5] # -> 1
	'аб' ~~ Varchar[2]  # -> 1
	'абв' ~~ Varchar[2] # -> ''

=head2 TinyText

Unicode string up to 255 characters: C<Uni & Len[255]>.

	'abc' ~~ TinyText    # -> 1
	'Привет' ~~ TinyText # -> 1

=head2 ShortText

Unicode string up to 65535 characters: C<Uni & Len[65_535]>.

	'abc' ~~ ShortText    # -> 1
	'Привет' ~~ ShortText # -> 1

=head2 MediumText

Unicode string up to 16777215 characters: C<Uni & Len[16_777_215]>.

	'abc' ~~ MediumText    # -> 1
	'Привет' ~~ MediumText # -> 1

=head2 LongText

Unicode string up to 4294967295 characters: C<Uni & Len[4_294_967_295]>.

	'abc' ~~ LongText    # -> 1
	'Привет' ~~ LongText # -> 1

=head2 TinyBlob

Binary data up to 255 bytes: C<Bin & Len[255]>.

	'bytes' ~~ TinyBlob # -> 1

=head2 ShortBlob

Binary data up to 65535 bytes: C<Bin & Len[65_535]>.

	'bytes' ~~ ShortBlob # -> 1

=head2 MediumBlob

Binary data up to 16777215 bytes: C<Bin & Len[16_777_215]>.

	'bytes' ~~ MediumBlob # -> 1

=head2 LongBlob

Binary data up to 4294967295 bytes: C<Bin & Len[4_294_967_295]>.

	'bytes' ~~ LongBlob # -> 1

=head2 Entity[class, appearance_key?]

Entity type: C<Object[class]>, which can be cast from an identifier string via C<coerce>. For C<Str>, it takes C<Appearance> (by default C<Aion::Aya::Appearance>), finds the model's primary key and searches for the object using it; if not found, leaves the line as is.

Used in C<< has ... isa =E<gt> Entity[...] >> so that an id can be passed instead of an object. An example is not given here: the constructor needs a working C<Aion::Aya::Appearance> with a base, and the library has not yet been completed.

=head1 GOTCHAS

=over

=item * B<< C<Entity> requires a working C<Appearance>. >> Casting C<Str → object> goes through C<< Aion-E<gt>pleroma-E<gt>resolve('Aion::Aya::Appearance') >> and C<QueryBuilder>, so the type does not work in isolation from the base/C<Appearance>.

=back

=head1 NOMENCLATURE

In the C<subtype "Name[A, b]", ...> declaration, the parameter names have the meaning:

=over

=item * B<One capital letter> (C<A>, C<B>, ...) - the parameter is an C<Aion::Type> object (the type itself), not a value. They work with it as with a type: C<< A-E<gt>test >>, C<< A-E<gt>include($val) >>.

=item * B<String names> (C<n>, C<from>, C<to>, C<a>, C<b>) are ordinary values, you can do arithmetic with them and substitute them into strings/regexp.

=back

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Types module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
