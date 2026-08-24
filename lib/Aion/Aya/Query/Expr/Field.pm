package Aion::Aya::Query::Expr::Field;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

has alias => (is => 'ro', isa => Str);
has name => (is => 'ro', isa => Str);
has entity => (is => 'ro', isa => ClassName);

1;