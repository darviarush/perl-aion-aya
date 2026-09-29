package Aion::Aya::Types;
# Типы для базы

use common::sense;

use Aion::Aya::QueryBuilder;
use Aion::Types;
use Exporter qw/import/;

our @EXPORT = our @EXPORT_OK = grep {
	*{$Aion::Types::{$_}}{CODE}	&& !/^(_|(NaN|import)\z)/n
} keys %Aion::Types::;

BEGIN {
#@category Валидаторы с запросами

	subtype "Entity[class, appearance_key?]", as Object[A], message { "Not exists ${\A()}<$_> in base" };

	# Конвертирует id в объект
	coerce &Entity, from Str, via {
		my $appearance = Aion->pleroma->resolve(B // 'Aion::Aya::Appearance');

		my $qb = Aion::Aya::QueryBuilder->new(
			_appearance => $appearance,
			_from => A,
		)->filter(id => $_);
	
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
	subtype "Decimal[A, B]", as Num, where { /^-?\d{0,${\(A - B)}}(?:\.\d+)?\z/ };

	subtype "Binary[A]",    as Bin & Len[A];
	subtype "Varbinary[A]", as Bin & Len[A];
	subtype "Char[A]",      as Uni & Len[A];
	subtype "Varchar[A]",   as Uni & Len[A];

	subtype "TinyText",   as Uni & Len[255];
	subtype "ShortText",  as Uni & Len[65_535];
	subtype "MediumText", as Uni & Len[16_777_215];
	subtype "LongText",   as Uni & Len[4_294_967_295];

	subtype "TinyBlob",   as Bin & Len[255];
	subtype "ShortBlob",  as Bin & Len[65_535];
	subtype "MediumBlob", as Bin & Len[16_777_215];
	subtype "LongBlob",   as Bin & Len[16_777_215];

}

1;
