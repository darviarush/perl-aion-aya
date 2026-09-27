package Aion::Aya::Adapter::Transform::Abstract;

use common::sense;

use Aion;

# Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic)
sub transform :Isa(Me => Query => Any);

1;