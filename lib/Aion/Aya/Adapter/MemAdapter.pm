package Aion::Aya::Adapter::MemAdapter;

use common::sense;

use Coro qw//;

use Aion;

has dsn => (is => 'ro', isa => Str, default => 'DBI:Mem:');
has login => (is => 'ro', isa => Undef);
has password => (is => 'ro', isa => Undef);
has attr => (is => 'ro', isa => HashRef, lazy => 0, default => sub {+{}});

with 'Aion::Aya::Adapter::Iterator::DBI';
with 'Aion::Aya::Adapter::Transform::SQL';

sub do { my $self = shift; Coro::cede; $self->next::do(@_); }
sub fetchrow { my $self = shift; Coro::cede; $self->next::fetchrow(@_); }
sub prepare { my $self = shift; Coro::cede; $self->next::prepare(@_); }
sub make_connect { my $self = shift; Coro::cede; $self->next::make_connect(@_); }
sub ping { my $self = shift; Coro::cede; $self->next::ping(@_); }

1;