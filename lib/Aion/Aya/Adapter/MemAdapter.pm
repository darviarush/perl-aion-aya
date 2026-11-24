package Aion::Aya::Adapter::MemAdapter;

use common::sense;

use Coro qw//;

use aliased 'Aion::Aya::Adapter::Transform::Abstract' => 'Transform';
use aliased 'Aion::Aya::Adapter::Transform::Mem' => 'TransformMem';

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';

# Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic)
has transformator => (is => 'ro', isa => Transform, default => sub { TransformMem->new });

# in-memory база работает без DSN-файла
sub default_dsn { 'DBI:Mem:' }

sub do { my $self = shift; Coro::cede; $self->next::do(@_); }
sub fetchrow { my $self = shift; Coro::cede; $self->next::fetchrow(@_); }
sub prepare { my $self = shift; Coro::cede; $self->next::prepare(@_); }
sub make_connect { my $self = shift; Coro::cede; $self->next::make_connect(@_); }
sub ping { my $self = shift; Coro::cede; $self->next::ping(@_); }

1;