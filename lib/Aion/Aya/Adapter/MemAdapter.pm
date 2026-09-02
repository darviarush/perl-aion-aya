package Aion::Aya::Adapter::MemAdapter;

use common::sense;

use Coro qw//;

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';
with 'Aion::Aya::Adapter::Transform::SQL';

sub do { my $self = shift; Coro::cede; $self->next::do(@_); }
sub fetchrow { my $self = shift; Coro::cede; $self->next::fetchrow(@_); }
sub prepare { my $self = shift; Coro::cede; $self->next::prepare(@_); }
sub make_connect { my $self = shift; Coro::cede; $self->next::make_connect(@_); }
sub ping { my $self = shift; Coro::cede; $self->next::ping(@_); }

1;