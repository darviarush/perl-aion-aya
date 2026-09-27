package Aion::Aya::Table;
# Таблица описывающая таблицу реляции в базе

use common::sense;

use List::Util qw//;

use Aion;

BEGIN {
	my %COLUMN = (
		name => Str,
		type => Str,
		is_nullable => Bool,
		default => Str,
		options => Str,
		comment => Str,
		order => Num,
	);

	subtype 'OptionColumn', as Dict[List::Util::pairmap { ($a => Option[$b]) } %COLUMN];
	
	subtype 'Column', as Dict[%COLUMN];

	subtype 'Key', as Dict[
		name => Str,
		columns => ArrayRef[Str],
		options => ArrayRef[Str],
	];

	subtype 'ForeignKey', as Dict[
		name => Str,
		to_table => PackageName,
		columns => ArrayRef[Str],
		to_columns => ArrayRef[Str],
		options => ArrayRef[Str],
	];
}

# Имя таблицы в базе
has table => (is => 'ro+', isa => Str);

# Опции таблицы в базе
has options => (is => 'ro', isa => Undef|Str|ArrayLike|HashLike);

# Первичный ключ
has primary_key => (is => 'ro+', isa => Key);

# Столбцы
has columns => (is => 'ro+', isa => ArrayRef[Column]);

# Уникальные ключи
has unique_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Индексы
has index_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Внешние ключи
has foreign_keys => (is => 'ro', isa => ArrayRef[ForeignKey], lazy => 0, default => sub {+[]});

1;