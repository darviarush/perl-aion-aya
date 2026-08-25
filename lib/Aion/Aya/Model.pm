package Aion::Aya::Model;

use common::sense;

use Aion;

use constant {
	PRIMARY_KEY => 'primary',
	UNIQUE_KEY => 'unique',
	INDEX_KEY => 'index',
};

BEGIN {
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

# Класс модели Aya
has pkg => (is => 'ro+', isa => PackageName);

# Имя таблицы в базе
has table => (is => 'ro+', isa => Str);

# Опции таблицы в базе
has options => (is => 'ro', isa => Undef|Str|ArrayLike|HashLike);

# Первичный ключ
has primary_key => (is => 'ro', isa => Key);

# Уникальные ключи
has unique_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Индексы
has index_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Внешние ключи
has foreign_keys => (is => 'ro', isa => ArrayRef[ForeignKey], lazy => 0, default => sub {+[]});

# Индексы в кеше: field => Key
has memory_key => (is => 'ro', isa => HashRef[Key], lazy => 0, default => sub {+[]});

# Индексы для загрузки нескольких полей из базы, если затронут только один
has fetch_key => (is => 'ro', isa => HashRef[Key], lazy => 0, default => sub {+[]});

# Возвращает имя столбца по полю
sub col_name {
	my ($self, $field) = @_;
	
	my $feature = $Aion::META{$self->{pkg}}{feature}{$field} or die "Not $field!";
	my $name = $feature->{name};
	
	if(my $col = $feature->{opt}{col}) {
		return $name if $col eq 1;
		return $col if !ref $col;
		return $col->{column};
	}

	if(my $ref = $feature->{opt}{ref}) {
		return "$name\_id" if $ref eq 1;
		return $ref->{column};
	}

	die "$field have'nt column!";
}

1;