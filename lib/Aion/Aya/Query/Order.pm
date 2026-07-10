package Aion::Aya::Query::Order;

use common::sense;

use Aion;

has desc => (is => 'ro', isa => Bool);
has op => (is => 'ro', isa => 'Aion::Aya::Query::Op');

1;