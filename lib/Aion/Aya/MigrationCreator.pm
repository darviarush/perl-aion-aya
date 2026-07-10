package Aion::Model::MigrationCreator;
# Типы для базы

use common::sense;

use Aion::Model::Config;

use Aion;

#
has config => (is => 'ro', isa => Object['Aion::Model::Config'], default => sub { Aion::Model::Config->new->load });

#  Создать миграцию
sub make {
	my ($self) = @_;

	my $config = Aion::Model::Config->new->load;

	for my $table (keys %{$config->table}) {
	}

	$self
}

# 
sub up {
	my ($self) = @_;

	$self
}

sub down {
	my ($self) = @_;

	$self
}

1;
