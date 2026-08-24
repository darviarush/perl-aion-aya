package Aion::Aya::Adapter;
# Осуществляет управление подключениями к базе, трансформирует

use common::sense;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Iterator';

use Aion -role;

# Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic)
sub transform :Isa(Me => Object[Query] => (ArrayRef|HashRef|Str));

sub iter :Isa(Me => Object[Iterator]);

sub next :Isa(Me => Any => Any);

1;