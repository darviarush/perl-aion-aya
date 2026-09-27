package Aion::Aya::Adapter::PgAdapter;

use common::sense;

use aliased 'Aion::Aya::Adapter::Transform::SQL';

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';

# Класс для сравнения модели и базы
has diff_class => (is => 'ro', isa => PackageName, default => 'Aion::Aya::Adapter::Diff::DDL');

# Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic)
has transformator => (is => 'ro', isa => SQL, default => sub { SQL->new });

1;