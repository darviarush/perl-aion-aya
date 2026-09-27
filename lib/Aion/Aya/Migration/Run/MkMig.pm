package Aion::Aya::Migration::Run::MkMig;
# Создаёт миграцию

use common::sense;

use Aion::Aya::Migration::Type qw/MigNum/;
use Aion::Fs qw/cat lay find to_pkg/;

use aliased 'Aion::Aya::Model';

use Aion;

with qw/Aion::Run/;

# Ключ адаптора в плероме
has adapter => (is => 'ro', isa => Str, arg => '-a', default => 'Aion::Aya::Adapter');

# Локатор
has pleroma => (is => 'ro', isa => 'Aion::Pleroma', eon => 1);

# Адаптер
has _adapter => (is => 'ro', isa => 'Aion::Aya::Adapter', default => sub {
	my ($self) = @_;
	$self->pleroma->resolve($self->adapter);
});

#@run aya:migration:mkmig „Create migration”
sub run {
	my ($self) = @_;

	my $comparator = $self->_adapter->comparator;

	my $struct_database = $comparator->structure;

	find "lib", "*.pm", sub {
		if(cat =~ /^use\s*Aion\s[^;]*\bAion::Aya[^:a-zA-Z_]/) {
			my $pkg = to_pkg;
			require $pkg unless $pkg ~~ ClassName;
		}
	0 };

	my %struct_model = map { ($_->table => $comparator->model2table($_)) } values %Aion::Aya::Model::META;

	my @up = $comparator->diff(\%struct_model, $struct_database);
	my @down = $comparator->diff($struct_database, \%struct_model);

	die "Need TODO!";
	# TODO:
	# 1. Обернуть @up в инструкции миграции и сформировать функцию up
	# 2. Обернуть @down в инструкции миграции и сформировать функцию down
	# 3. Сформировать класс миграции и записать его через Aion::Fs lay в migrations/year{4}/month{2}/Migration{MigNum}.pm. migrations взять из Aion::Env AION_MIGRATIONS_PATH => (default => 'migrations');
	# 4. В классе миграции должен быть указан адаптор с ключом из свойства adaptor этой команды. Если он совпадает с 'Aion::Aya::Adaptor', то eon => 1.
	# 
	# Пример класса миграции:
	# package Migration20260927221733;
	#
	# use common::sense;
	# 
	# use Aion;
	#
	# has adaptor => (is => 'ro', isa => 'Aion::Aya::Adaptor', eon => 1);
	#
	# sub up {
	# 	my ($self) = @_;
	# 	
	# 	$self->adaptor->do(q{CREATE TABLE ...});
	# }
	# 
	# sub down {
	# 	my ($self) = @_;
	# 	
	# 	$self->adaptor->do(q{DROP TABLE ...});
	# }
	#
	# 1;
}

1;
