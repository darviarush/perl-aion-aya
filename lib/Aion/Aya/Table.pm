package Aion::Aya::Table;
# Таблица описывающая таблицу реляции в базе

use common::sense;

use Aion;

BEGIN {
	subtype 'Column', as Dict[
		name => Option[Str],
		type => Option[Str],
		is_nullable => Option[Bool],
		default => Option[Str],
		options => Option[Str],
		comment => Option[Str],
		order => Option[Num],
	]; 

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

# Столбцы
has columns => (is => 'ro', isa => ArrayRef[Column], default => \&_column_builder);

# Первичный ключ
has primary_key => (is => 'ro', isa => Key);

# Уникальные ключи
has unique_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Индексы
has index_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Внешние ключи
has foreign_keys => (is => 'ro', isa => ArrayRef[ForeignKey], lazy => 0, default => sub {+[]});

sub _column_builder { die "Not implemented" }

1;