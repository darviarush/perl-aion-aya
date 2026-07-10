package Aion::Aya::Box;

use common::sense;

use aliased 'Aion::Aya::QueryBuilder';
use aliased 'Aion::Aya::Query::Expr::Field';
use aliased 'Aion::Aya::Query::Expr::Val';
use aliased 'Aion::Aya::Query::Order';

use Aion -role;

my @export = qw/box_for F NOT EXIST COUNT SUM AVG CAST DESC ASC/;

sub import {
	my (undef, @attrs) = @_;
	my $pkg = caller;

	local $" = " ";
	eval "use Aion qw/@attrs/; with qw/Aion::Aya::Box/; 1" or die;
	
	*{"$pkg\::$_"} = \&$_ for @export;
}

sub unimport {
	my (undef, @attrs) = @_;
	my $pkg = caller;

   	local $" = " ";
	eval "no Aion qw/@attrs/; 1" or die;
	
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
	
	QueryBuilder->new(box_for => $self->box_for, appearance => $self->_appearance);
}

sub F($) {
	my ($name) = @_;
	Field->new(name => $name);
}

sub V($) {
	my ($scalar) = @_;
	Val->new(value => $scalar);
}

sub desc($) {
	my ($op) = @_;
	Order->new(op => $op, desc => 1);
}

sub asc($) {
	my ($op) = @_;
	Order->new(op => $op, desc => 0);
}

#@category Функции и унарные операторы

#sub EXISTS {
#	my ($self) = @_;
#	Fn->new(name => 'count', args => [$op]);
#}

#sub count {
#	my ($arg) = @_;
#	Fn->new(name => 'count', args => [$arg]);
#}

#sub SUM {
#	my ($self) = @_;
	
#	$self
#}

#sub AVG {
#	my ($self, ) = @_;
#	Fn->new(name => 'avg', args => []);
#}

#sub CAST {
#	my ($self, ) = @_;
#	Fn->new(name => 'avg', args => );
#}

#sub F($) {
#	my ($field) = @_;
#	Field->new(name => $field);
#}

#sub DESC($) {
#	my ($op) = @_;
#	Order->new(desc => 1, operand => $op);
#}

#sub ASC($) {
#	my ($op) = @_;
#	Order->new(operand => $op);
#}

1;
