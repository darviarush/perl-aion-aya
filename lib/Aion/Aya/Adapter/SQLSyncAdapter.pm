package Aion::Aya::Adapter::SQLSyncAdapter;

use common::sense;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Iterator';

use Aion;

with 'Aion::Aya::Adapter';
with 'Aion::Aya::Adapter::Iterator::DbSync';
with 'Aion::Aya::Adapter::Transform::SQL';

1;