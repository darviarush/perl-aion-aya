package Aion::Aya::Adapter;
# Осуществляет управление подключениями к базе, трансформирует

use common::sense;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Iterator';
use aliased 'Aion::Aya::Model';

use Aion -role;

req dsn => (is => 'ro', isa => Str);
req login => (is => 'ro', isa => Maybe[Str]);
req password => (is => 'ro', isa => Maybe[Str]);
req attr => (is => 'ro', isa => HashRef);

# Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic)
sub transform :Isa(Me => Object[Query] => (ArrayRef|HashRef|Str));

# Порождает итератор
sub iterator :Isa(Me => Object[Query] => Object[Iterator]);

# Следующее значение из сессии (второй параметр) или undef
sub next :Isa(Me => Hashref => Any);

# Сгенерированные прокси-классы сущностей: базовый класс => набор алиасов => имя класса
my %PROXY;

# Возвращает класс, в который превратить строку: сам класс сущности, если все алиасы — его
# столбцы, либо сгенерированный прокси-класс с дополнительными алиасами
sub _entity_class {
	my ($self, $query, $row) = @_;

	my $base = $query->from;
	my %cols = map {($_ => 1)} Model->get($base)->cols;
	my @extra = grep { !$cols{$_} } keys %$row;
	return $base unless @extra;

	$self->_proxy_class($base, \@extra);
}

# Создаёт (или возвращает уже созданный) прокси-класс: наследник $base с дополнительными
# полями-алиасами. Имя генерируется как "$base_<случайное число в 16-ричном виде>"
sub _proxy_class {
	my ($self, $base, $extra) = @_;

	my $extra_key = join "\x1F", sort @$extra;
	return $PROXY{$base}{$extra_key} if exists $PROXY{$base}{$extra_key};

	my $name = $base . '_' . sprintf('%014x', int(rand(0xFFFFFFFFFFFF)));
	my $fields = join '', map { "has '$_' => (is => 'ro', isa => Any);\n" } @$extra;
	eval "package $name;\nuse Aion;\nextends '$base';\n$fields\n1;\n" or die $@;

	$PROXY{$base}{$extra_key} = $name;
}

1;