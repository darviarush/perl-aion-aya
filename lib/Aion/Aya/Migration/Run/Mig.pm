package Aion::Aya::Migration::Run::Mig;
# Выполняет миграцию

use common::sense;

use Aion::Aya::Migration::Type qw/MigNum/;

use aliased 'Aion::Aya::Model';

use Aion;

with qw/Aion::Run/;

# Откатить миграцию
has down => (is => 'ro', isa => Bool, arg => -d);

# Номер миграции
has migration => (is => 'ro', isa => MigNum, arg => 1);

#@run aya:migratio:mig „Up/down migration”
sub mig {
	my ($self) = @_;

	die "" unless defined $self->migration;
	
	if($self->down) {
	}
	else {
	}
}

1;
