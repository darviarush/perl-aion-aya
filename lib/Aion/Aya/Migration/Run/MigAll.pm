package Aion::Aya::Migration::Run::MigAll;
# Выполняет миграцию

use common::sense;

use Aion::Aya::Migration::Type qw/MigNum/;

use aliased 'Aion::Aya::Model';

use Aion;

with qw/Aion::Run/;

# Откатить миграции
has down => (is => 'ro', isa => Bool, arg => -d);

# Номер миграции
has migration => (is => 'ro', isa => Maybe[MigNum], arg => 1);

#@run aya:migration:migall „Up/down all migration”
sub migall {
	my ($self) = @_;
	
	if($self->down) {	
		# Накатить все миграции, которые ещё не были накачены до указанной
	}
	else {
		# Откатить все накачанные миграции до указанной
	}
}

1;
