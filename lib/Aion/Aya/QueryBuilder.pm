package Aion::Aya::QueryBuilder;
# Заполняет Query

use common::sense;

use aliased 'Aion::Aya::Query';

use Aion;

# Запрос
has _query => (is => 'ro-', isa => Query, lazy => 0, defalt => sub { Query->new });

#@category Описатели

sub inner_join {
	my ($self, $alias, $field) = @_;
	$self->_query->clone(join => +{ %{$self->_query->join}, $alias => xJoin->new(field => $field, alias => $alias, join => 'inner') });
}

sub left_join {
	my ($self, $alias, $field) = @_;
	$self->_query->clone(join => +{ %{$self->_query->join}, $alias => xJoin->new(field => $field, alias => $alias, join => 'left') });
}

sub annotate {
	my ($self, @select) = @_;
	$self->_query->clone(select => \@select);
}

sub add_annotate {
	my ($self, @select) = @_;
	$self->_query->clone(select => +{%{$self->select}, @select});
}

sub filter {
	my ($self, $op) = @_;
	$self->_query->clone(filter => $op);
}

sub and_filter {
	my ($self, $op) = @_;
	$self->_query->clone(filter => Op->new(left => $self->filter, op => 'AND', right => $op));
}

sub or_filter {
	my ($self, $op) = @_;
	$self->_query->clone(filter => Op->new(left => $self->filter, op => 'OR', right => $op));
}

sub group_by {
	my ($self, @groups) = @_;
	$self->_query->clone(group_by => \@groups);
}

sub add_group_by {
	my ($self, @groups) = @_;
	$self->_query->clone(group_by => [@{$self->_group_by}, @groups]);
}

sub having {
	my ($self, $op) = @_;
	$self->_query->clone(having => $op);
}

sub and_having {
	my ($self, $op) = @_;
	$self->_query->clone(having => Op->new(left => $self->filter, op => 'AND', right => $op));
}

sub or_having {
	my ($self, $op) = @_;
	$self->_query->clone(having => Op->new(left => $self->filter, op => 'OR', right => $op));
}

sub order_by {
	my ($self, @orders) = @_;
	$self->_query->clone(order_by => \@orders);
}

sub add_order_by {
	my ($self, @orders) = @_;
	$self->_query->clone(order_by => [@{$self->order_by}, @orders]);
}

sub offset {
	my ($self, $offset) = @_;
	 $self->_query->clone(offset => $offset);
}

sub limit {
	my ($self, $limit) = @_;
	 $self->_query->clone(limit => $limit);
}

#@category Получатели

sub iter {
	my ($self) = @_;
	
	->new
}

sub iter_or_array {
	my ($self) = @_;
	wantarray? $self->as_array: $self->iter;
}

sub as_array {
	my ($self) = @_;
	die "Not array context!" unless wantarray;
	@{$self->iter};
}

sub first {
	my ($self) = @_;
	my $iter = $self->iter;
	my $first = $iter->next;
	
	$first
}

sub scalar {
	my ($self, $field) = @_;
	$self->first->$field;
}

sub column {
	my ($self, $field) = @_;
	my $iter = $self->iter;
	my @column;
	push @column, $_->$field while <$iter>;
	wantarray? @column: \@column;
}

sub count {
	my ($self) = @_;
	$self->annotate(Fn->new(name => 'count') => -count)->scalar(-count);
}

sub sum {
	my ($self) = @_;
	$self->annotate(Fn->new(name => 'sum') => -sum)->scalar(-sum);
}

sub avg {
	my ($self) = @_;
	$self->annotate(Fn->new(name => 'avg') => -avg)->scalar(-avg);
}

1;