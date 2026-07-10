package Aion::Aya::Query::Expr::Op;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

has op => (is => 'ro', isa => Str);
has left => (is => 'ro', isa => 'Aion::Aya::Query::Expr');
has right => (is => 'ro', isa => 'Aion::Aya::Query::Expr');

1;