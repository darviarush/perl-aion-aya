package Aion::Aya::Model;
# Модель описывающая объект реляции в ORM

use common::sense;

use aliased 'Aion::Aya::Table';

use Aion;

extends Table;

BEGIN {
	subtype 'Field', as Dict[
		name => Str,
		type => Enum[qw/col ref bk m2m/],
		col_name => Option[Str], # столбец есть у col и ref. Описание его в column
		ref => Option[Tuple[PackageName, Str, Maybe[Str]]], # ссылка на другую модель. Используется ref и bk
		table => Option[Table], # для m2m связей – ссылка на промежуточную таблицу
	];

	subtype 'MemoryKey', as Dict[
		key => Str,
		fields => ArrayRef[Str],
	];

	subtype 'FetchKey', as Dict[
		fields => ArrayRef[Str],
	];
}

# Класс модели Aya
has pkg => (is => 'ro+', isa => PackageName);

# Генератор следующего значения
has next => (is => 'ro', isa => Object|Str|Undef);

# Поля
has field => (is => 'ro', isa => HashRef[Field]);

# Индексы в кеше: field => Key
has memory_key => (is => 'ro', isa => HashRef[MemoryKey], lazy => 0, default => sub {+[]});

# Индексы для загрузки нескольких полей из базы, если затронут только один
has fetch_key => (is => 'ro', isa => HashRef[FetchKey], lazy => 0, default => sub {+[]});

# Вернуть модель по классу или объекту
sub get {
	my ($self, $object) = @_;
	my $pkg = ref $object || $object;
	$Aion::Aya::META{$pkg} // die "Not model from $pkg"
}

# Возвращает фичу по называнию поля 
sub feature {
	my ($self, $field) = @_;
	$Aion::META{$self->{pkg}}{feature}{$field} // die "Not $field!"
}

# Возвращает имена полей, являющиеся col или ref
sub cols {
	my ($self) = @_;
	my $feature = $Aion::META{$self->{pkg}}{feature};
	grep { exists $feature->{opt}{col} || exists $feature->{opt}{ref} } keys %$feature;
}

# Возвращает имя столбца по полю
sub col_name {
	my ($self, $field) = @_;
	
	$self->{field}{$field}{col_name} // die "$field have'nt column!";
}

# Возвращает
sub get_ref {
	my ($cls, $feature) = @_;

	my $isa = $feature->{isa}{name} eq 'Maybe'? $feature->{isa}{args}[0]: $feature->{isa};

	die "$feature->{name} with ref: isa maybe Object!" unless $isa->{name} eq 'Object';

	$isa->{args}[0]
}

# Добавляет основной ключ
sub add_primary_key {
	my ($self, $fields, $options) = @_;

	die "Primary key is already installed!" if exists $self->{primary_key};
    $self->primary_key({fields => $fields, options => $options});
	
	$self
}

# Добавляет уникальный ключ
sub add_unique_key {
	my ($self, $name, $fields, $options) = @_;

	my $key = {name => $name, fields => $fields, options => $options};
	Key->validate($key, "unique_key $name");
	push @{$self->{unique_keys}}, $key;
	
	$self
}

# Добавляет мультипликативный ключ
sub add_index_key {
	my ($self, $name, $fields, $options) = @_;

	my $key = {name => $name, fields => $fields, options => $options};
	Key->validate($key, "index_key $name");
	push @{$self->{index_keys}}, $key;
	
	$self
}

# Добавляет мультипликативный ключ
sub add_foreign_key {
	my ($self, $name, $to_class, $fields, $to_fields, $options) = @_;

	my $key = {name => $name, to_class => $to_class, fields => $fields, to_fields => $to_fields, options => $options};
	ForeignKey->validate($key, "foreign_key $name");
	push @{$self->{foreign_keys}}, $key;
	
	$self
}

# Добавляет памятный ключ
sub add_memory_key {
	my ($self, $key_format, $fields, $options) = @_;

	my $key = {key_format => $key_format, fields => $fields, options => $options};
	MemoryKey->validate($key, "memory_key $key_format");
	for my $field (@$fields) {
		die "$key_format and $self->{memory_key}{$_}{key_format} memory_keys use one field $field!" if exists $self->{memory_key}{$_};
		$self->{memory_key}{$_} = $key;
	}
	
	$self
}

# Добавляет ключ извлечения связанных столбцов
sub add_fetch_key {
	my ($self, $fields) = @_;

	my $name = join "-", @$fields;
	my $key = {fields => $fields};
	FetchKey->validate($key, "fetch_key");
	for my $field (@$fields) {
		die "$name and $self->{fetch_key}{$_}{name} fetch_keys use one field $field!" if exists $self->{fetch_key}{$_};
		$self->{fetch_key}{$_} = $key;
	}
	
	$self
}

# Создаёт триггеры на фиче
sub make_column_feature {
	my ($cls, $feature) = @_;
	my $name = $feature->{name};
	$feature->construct
		->add_access("\$self->_appearance->fetch(\$self, '$name') unless exists \$self->{$name};")
		->add_trigger("\$self->_appearance->store(\$self, '$name')")
		->add_cleaner("\$self->_appearance->clear(\$self, '$name')")
	;
}

1;