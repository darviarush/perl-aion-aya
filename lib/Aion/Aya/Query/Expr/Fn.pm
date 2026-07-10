package Aion::Aya::Query::Expr::Fn;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

has name => (is => 'ro', isa => Str);
has args => (is => 'ro', isa => ArrayRef['Aion::Aya::Query::Expr']);

1;