package Aion::Aya::Table;
# Таблица описывающая таблицу реляции в базе

use common::sense;

use Aion;

our %COLUMN = (
	name => Str,
	type => Str,
	is_nullable => Bool,
	default => Str,
	options => Str,
	comment => Str,
	order => Num,
);

BEGIN {
	subtype 'Column', as Dict[%COLUMN];

	subtype 'Key', as Dict[
		name => Str,
		fields => ArrayRef[Str],
		options => ArrayRef[Str],
	];

	subtype 'ForeignKey', as Dict[
		name => Str,
		to_class => PackageName,
		fields => ArrayRef[Str],
		to_fields => ArrayRef[Str],
		options => ArrayRef[Str],
	];
}

# Имя таблицы в базе
has table => (is => 'ro+', isa => Str);

# Опции таблицы в базе
has options => (is => 'ro', isa => Undef|Str|ArrayLike|HashLike);

# Столбцы. Используются только в миграции
has columns => (is => 'rw', isa => ArrayRef[Column]);

# Первичный ключ
has primary_key => (is => 'rw', isa => Key);

# Уникальные ключи
has unique_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Индексы
has index_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Внешние ключи
has foreign_keys => (is => 'ro', isa => ArrayRef[ForeignKey], lazy => 0, default => sub {+[]});

1;