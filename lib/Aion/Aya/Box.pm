package Aion::Aya::Box;

use common::sense;

use aliased 'Aion::Aya::QueryBuilder';
use aliased 'Aion::Aya::Query::Expr::Field';
use aliased 'Aion::Aya::Query::Expr::Val';
use aliased 'Aion::Aya::Query::Order';

use Aion -role;

my @export = qw/box_for F EXIST COUNT MIN MAX SUM AVG CAST DESC ASC/;

sub import {
	my (undef, @attrs) = @_;
	my $pkg = caller;

	local $" = " ";
	my $attrs = @attrs? " qw{@attrs}": "";
	eval "use Aion$attrs; with qw/Aion::Aya::Box/; 1" or die;
	
	*{"$pkg\::$_"} = \&$_ for @export;
}

sub unimport {
	my (undef, @attrs) = @_;
	my $pkg = caller;

   	local $" = " ";
    my $attrs = @attrs? " qw{@attrs}": "";
	eval "no Aion$attrs; 1" or die;
	
	undef &{"$pkg\::$_"} for @export;
}

# Устанавливает/возвращает класс объектов
sub box_for($) {
	my ($class) = @_;
	my $pkg = caller;
	*{"$pkg\::box_for"} = sub($){$class};
	return;
}

# Управляющий сущностями
has _appearance => (is => 'ro', isa => 'Aion::Aya::Appearance', eon => 1);

# Создаёт QueryBuilder
sub query_builder {
	my ($self) = @_;
	
	QueryBuilder->new(_from => $self->box_for, _appearance => $self->_appearance);
}

sub F($) {
	my ($name) = @_;
	Field->new(name => $name, from => caller()->box_for);
}

sub V($) {
	my ($scalar) = @_;
	Val->new(value => $scalar);
}

my $desc;
sub DESC() {
	$desc //= Order->new(desc => 1);
}

my $asc;
sub ASC() {
	$asc //= Order->new(desc => 0);
}

#@category Функции и унарные операторы

sub EXISTS {
	my ($self) = @_;
	Fn->new(name => 'exists', args => [$op]);
}

sub COUNT {
	my ($arg) = @_;
	Fn->new(name => 'count', args => [$arg]);
}

sub MIN {
	my ($arg) = @_;
	Fn->new(name => 'min', args => [$arg]);
}

sub MAX {
	my ($arg) = @_;
	Fn->new(name => 'max', args => [$arg]);
}

sub SUM {
	my ($self, $exp) = @_;
	Fn->new(name => 'sum', args => [$exp]);
}

sub AVG {
	my ($self, $exp) = @_;
	Fn->new(name => 'avg', args => [$exp]);
}

sub CAST {
	my ($self, $exp, $type) = @_;
	Fn->new(name => 'cast', args => [$exp, $type]);
}

1;
