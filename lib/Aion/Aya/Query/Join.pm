package Aion::Aya::Query::Join;

use common::sense;

use Aion;

has field => (is => 'ro', isa => Str);
has alias => (is => 'ro', isa => Str);
has join => (is => 'ro', isa => Enum[qw/inner left/]);

1;