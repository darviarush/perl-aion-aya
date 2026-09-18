package Aion::Aya::Model;
# Модель описывающая объект реляции в ORM

use common::sense;

use Aion;

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

# Генератор следующего значения
has next => (is => 'ro', isa => Object|Str|Undef);

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

sub _find_aya(@);

# Модели проекта
has models => (is => 'ro', isa => ArrayRef[ClassName], default => sub {
	my ($self) = @_;

	my $aya_files = _find_aya "lib";

	for my $aya_file ($aya_files) {
		require $aya_file unless $aya_file ~~ ClassName and ;
	}

	sort keys %Aion::Aya::META;
});

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

# Возвращает информацию о столбце по называнию поля 
sub col {
	my ($self, $field) = @_;
	$self->feature->{opt}{col} // die "Not col on $field!"
}

# Возвращает имя столбца по полю
sub col_name {
	my ($self, $field) = @_;
	
	my $feature = $self->feature($field);
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

my @_aya_path;
sub _find_aya(@) {
    my @dirs = @_;
    while(@dirs) {
    	my $dir = pop @dirs;
     	opendir my $dh, $dir or die "$dir: $!";
	    while(my $file = readdir $dh) {
			next if $file =~ /^\.\.?$/;
			my $path = "$dir/$file";
			if(-d $path) {
	        	push @dirs, $path;
			}
			elsif($path =~ /\.pm$/) {
				open my $f, "<:encode(utf8)", $path or die "$path: $!";
				while(<$f>) {
					last if /^__(END|DATA)__$/;
					if(/^use\s*Aion::Aya\s*;/) {
						push @_aya_path, $path;
					 	last;
					}
				}
				close $f;
			}
	    }
		closedir $dh;
	}

    \@_aya_path;
}

1;