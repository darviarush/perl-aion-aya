package Aion::Aya::Model;
# Модель описывающая объект реляции в ORM

use common::sense;

use aliased 'Aion::Aya::Table';

use Aion;

extends Table;

BEGIN {
	subtype 'Field', as Dict[
		name => Str,
		type => Enum[qw/col ref bk m2m n2m m2n/],
		col_name => Option[Str], # столбец есть у col и ref. Описание его в column
		ref => Option[Tuple[PackageName, Str]], # ссылка на другую модель. Используется ref и bk
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
	my ($self, $feature) = @_;

	my $isa = $feature->{isa}{name} eq 'Maybe'? $feature->{isa}{args}[0]: $feature->{isa};

	die "$feature->{name} with ref: isa maybe Object!" unless $isa->{name} eq 'Object';

	$isa->{args}[0]
}

# Создаёт триггеры на фиче
sub make_column_feature {
	my ($self, $feature) = @_;
	my $name = $feature->{name};
	$feature->construct
		->add_access("\$self->_appearance->fetch(\$self, '$name') unless exists \$self->{$name};")
		->add_trigger("\$self->_appearance->store(\$self, '$name')")
		->add_cleaner("\$self->_appearance->clear(\$self, '$name')")
	;
}

sub _column_builder {
	my ($self) = @_;

	my $feature_href = $Aion::META{ref $self}{feature}; 
	
	for my $field (%{$self->{field}}) {
		my $feature = $feature_href->{$field};
		my $isa = $feature->{isa};
		my $is_nullable = $isa->{name} eq 'Maybe'? do { $isa = $isa->{args}[0]; 1 }: 0;
		my %column = (
			name => $self->col_name(),
			is_nullable => $is_nullable,
		);
	}
	
}

1;