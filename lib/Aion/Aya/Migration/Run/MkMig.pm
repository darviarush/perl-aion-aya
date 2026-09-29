package Aion::Aya::Migration::Run::MkMig;
# Создаёт миграцию

use common::sense;

use POSIX qw/strftime/;

use Aion::Aya::Migration::Types qw/MigNum MIGRATIONS_PATH/;
use Aion::Fs qw/cat lay find mkpath to_pkg/;

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
			require $pkg unless $pkg->can('new');
		}
	0 };

	my %struct_model = map { ($_->table => $comparator->model2table($_)) } values %Aion::Aya::META;

	my @up = $comparator->diff(\%struct_model, $struct_database);
	my @down = $comparator->diff($struct_database, \%struct_model);

	# Номер миграции и путь к файлу миграции
	my $mig_num = strftime "%Y%m%d%H%M%S", localtime;
	my ($year, $month) = $mig_num =~ /^(\d{4})(\d{2})/;
	my $pkg = "Migration$mig_num";
	my $path = join '/', MIGRATIONS_PATH, $year, $month, "$pkg.pm";

	# Класс миграции: адаптор берётся по ключу из свойства adapter команды
	my $adaptor = $self->adapter;
	my $up = join '', map { "\tq{$_},\n" } @up;
	my $down = join '', map { "\tq{$_},\n" } @down;

	my $code = <<"END";
package $pkg;

use common::sense;

use Aion;

has adaptor => (is => 'ro', isa => Object['$adaptor'], eon => 1);

sub up {
	my (\$self) = \@_;
	my \$dbh = \$self->adaptor->connect;
	\$self->adaptor->do(\$dbh, \$_) for (
$up	);
	\$self->adaptor->finish(\$dbh);
}

sub down {
	my (\$self) = \@_;
	my \$dbh = \$self->adaptor->connect;
	\$self->adaptor->do(\$dbh, \$_) for (
$down	);
	\$self->adaptor->finish(\$dbh);
}

1;
END

	mkpath $path;
	lay $path, $code;

	$self
}

1;
