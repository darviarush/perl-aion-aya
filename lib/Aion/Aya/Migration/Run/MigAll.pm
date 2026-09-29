package Aion::Aya::Migration::Run::MigAll;
# Выполняет все миграции

use common::sense;

use Aion::Aya::Migration::Types qw/MigNum MIGRATIONS_PATH/;
use Aion::Fs qw/find/;

use aliased 'Aion::Aya::Model';

use Aion;

with qw/Aion::Run/;

# Откатить миграции
has down => (is => 'ro', isa => Bool, arg => -d);

# Номер миграции
has migration => (is => 'ro', isa => Maybe[MigNum], arg => 1);

#@run aya:migration:migall „Up/down all migration”
sub run {
	my ($self) = @_;

	# Пути миграций в порядке возрастания номера
	my @paths = sort find MIGRATIONS_PATH, '*.pm';
	my @pkg = map { _pkg($_) } @paths;

	# До какого номера выполнять (включительно)
	my $upto = defined $self->migration? "Migration${\$self->migration}": undef;

	if($self->down) {
		# Откатываем накатанные миграции от старших к младшим до указанной
		for my $i (reverse 0..$#paths) {
			my $pkg = $pkg[$i] // next;
			next if defined $upto && $pkg le $upto;
			require "./$paths[$i]";
			$pkg->new->down;
		}
	}
	else {
		# Накатываем миграции от младших к старшим до указанной
		for my $i (0..$#paths) {
			my $pkg = $pkg[$i] // next;
			next if defined $upto && $pkg gt $upto;
			require "./$paths[$i]";
			$pkg->new->up;
		}
	}

	$self
}

# Имя пакета миграции по пути к её файлу
sub _pkg {
	my ($path) = @_;
	$path =~ m{/(Migration\d+)\.pm\z}? $1: undef;
}

1;
