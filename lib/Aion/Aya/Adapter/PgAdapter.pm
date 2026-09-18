package Aion::Aya::Adapter::PgAdapter;

use common::sense;

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';
with 'Aion::Aya::Adapter::Transform::SQL';

# Класс для сравнения модели и базы
has diff_class => (is => 'ro', isa => PackageName, default => 'Aion::Aya::Adapter::Diff::DDL');

1;