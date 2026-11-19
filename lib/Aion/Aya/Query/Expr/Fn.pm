package Aion::Aya::Query::Expr::Fn;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

# Имя функции
has name => (is => 'ro', isa => Str);

# Аргументы
has args => (is => 'ro', isa => ArrayRef['Aion::Aya::Query::Expr']);

1;