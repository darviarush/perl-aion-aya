package Aion::Aya::Adapter::MemAdapter;

use common::sense;

use Coro::Mysql;

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';
with 'Aion::Aya::Adapter::Transform::SQL';

1;