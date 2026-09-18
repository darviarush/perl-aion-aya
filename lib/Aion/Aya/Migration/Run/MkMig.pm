package Aion::Aya::Migration::Run::MkMig;
# Создаёт миграцию

use common::sense;

use Aion::Aya::Migration::Type qw/MigNum/;

use aliased 'Aion::Aya::Model';

use Aion;

with qw/Aion::Run/;

#@run aya:migration:mkmig „Create migration”
sub mkmig {
	my ($self) = @_;

	$self
}

1;
