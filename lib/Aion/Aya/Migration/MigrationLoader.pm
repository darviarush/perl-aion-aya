package Aion::Aya::Migration::MigrationLoader;
# Выполняет миграцию

use common::sense;

use aliased 'Aion::Aya::Model';

use Aion;

# Накатить миграцию
sub up {
	my ($self) = @_;

	$self
}

# Откатить миграцию
sub down {
	my ($self) = @_;

	$self
}

# Накатить все миграции, которые ещё не были накачены до указанной
sub up_all {
	my ($self, $migration) = @_;

	$self
}

# Откатить все накачанные миграции до указанной
sub down_all {
	my ($self, $migration) = @_;

	$self
}

1;
