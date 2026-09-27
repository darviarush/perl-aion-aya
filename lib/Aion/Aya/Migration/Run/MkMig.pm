package Aion::Aya::Migration::Run::MkMig;
# Создаёт миграцию

use common::sense;

use Aion::Aya::Migration::Type qw/MigNum/;
use Aion::Fs qw/cat lay find to_pkg/;

use aliased 'Aion::Aya::Model';

use Aion;

with qw/Aion::Run/;

# Адаптер
has adapter => (is => 'ro', isa => 'Aion::Aya::Adapter', eon => 1);

#@run aya:migration:mkmig „Create migration”
sub run {
	my ($self) = @_;

	my $comparator = $self->adapter->comparator;

	my $struct_database = $comparator->structure;

	find "lib", "*.pm", sub {
		if(cat =~ /^use\s*Aion\s[^;]*\bAion::Aya[^:a-zA-Z_]/) {
			my $pkg = to_pkg;
			require $pkg unless $pkg ~~ ClassName;
		}
	0 };

	my %struct_model = map { $comparator->build_columns($_); ($_->table => $_) } values %Aion::Aya::Model::META;
	
	my @up = $comparator->diff(\%struct_model, $struct_database);
	my @down = $comparator->diff($struct_database, \%struct_model);

	die "Need TODO!";
	# TODO:
	# 1. Обернуть @up в инструкции миграции и сформировать функцию up
	# 2. Обернуть @down в инструкции миграции и сформировать функцию down
	# 3. Сформировать класс миграции и записать его через Aion::Fs lay в migrations/year4/month2/MigNum.pm
}

1;
