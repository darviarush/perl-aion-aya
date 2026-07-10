package Aion::Aya::Query::Expr::UOp;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

has op => (is => 'ro', isa => Str);
has exp => (is => 'ro', isa => 'Aion::Aya::Query::Expr');

1;