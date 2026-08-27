package Aion::Aya::Adapter;
# Осуществляет управление подключениями к базе, трансформирует

use common::sense;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Iterator';

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

1;