package Aion::Aya::Adapter::Transform::SQL;

use common::sense;

use List::Util qw/pairmap/;

use aliased 'Aion::Aya::Query::Expr::Field';
use aliased 'Aion::Aya::Query::Expr::Op';
use aliased 'Aion::Aya::Query::Expr::UOp';
use aliased 'Aion::Aya::Query::Expr::Val';
use aliased 'Aion::Aya::Model';

use Aion -role;

# Трансформирует запрос в промежуточное представление
sub transform :Isa(Me => Query => Str) {
	my ($self, $query) = @_;

	do {
		given($query->operation) {
			$self->sql_select($query) when Query->SELECT;
			$self->sql_insert($query) when Query->INSERT;
			$self->sql_update($query) when Query->UPDATE;
			$self->sql_delete($query) when Query->DELETE;
		}
	}
}

# Общие части select-запроса: join, where, group by, having, order by, limit, offset
sub _select {
	my ($self, $query) = @_;

	my @join  = map {"\nJOIN "} %{$query->{join}};
	my @group = map { $self->expr($_) } @{$query->{group_by}};
	my @order = pairmap { ($self->expr($a), ' ', $b) } @{$query->{order_by}};

	my $limit  = defined $query->{limit}?  ' LIMIT '  . $query->{limit}:  '';
	my $offset = defined $query->{offset}? ' OFFSET ' . $query->{offset}: '';

	join '', @join,
		$query->{filter}? ' WHERE ' . $self->expr($query->{filter}): '',
		@group? ' GROUP BY ' . join(', ', @group): '',
		$query->{having}? ' HAVING ' . $self->expr($query->{having}): '',
		@order? ' ORDER BY ' . join(', ', @order): '',
		$limit, $offset;
}

# Конструирует select-запрос SQL
sub sql_select {
	my ($self, $query) = @_;

	my @fields = pairmap {($self->expr($a), ' as ', $self->word($b))} @{$query->{select}};
	my $table = $self->word(Model->get($query->from)->table);

	join '', 'SELECT ', @fields? @fields: '*', ' FROM ', $table, $self->_select($query);
}

# Конструирует insert-запрос SQL. Пары select — это значение поля и имя поля
sub sql_insert {
	my ($self, $query) = @_;

	my (@cols, @vals);
	my @pairs = @{$query->{select}};
	while (@pairs) {
		my $value = shift @pairs;
		my $name  = shift @pairs;
		push @cols, $self->word($name);
		push @vals, $self->expr($value);
	}

	my $table = $self->word(Model->get($query->from)->table);
	my $cols  = ' (' . join(', ', @cols) . ')';

	# Если кроме select заданы ещё join, where и т.д. — формируем INSERT ... SELECT
	if ($query->{filter} || @{$query->{join}} || @{$query->{group_by}} || $query->{having} || @{$query->{order_by}} || defined $query->{limit} || defined $query->{offset}) {
		my $from = $self->word(Model->get($query->from)->table);
		return join '', 'INSERT INTO ', $table, $cols, ' SELECT ', join(', ', @vals), ' FROM ', $from, $self->_select($query);
	}

	join '', 'INSERT INTO ', $table, $cols, ' VALUES (', join(', ', @vals), ')';
}

# Конструирует update-запрос SQL. Пары select — это значение поля и имя поля
sub sql_update {
	my ($self, $query) = @_;

	my @set;
	my @pairs = @{$query->{select}};
	while (@pairs) {
		my $value = shift @pairs;
		my $name  = shift @pairs;
		push @set, $self->word($name) . ' = ' . $self->expr($value);
	}

	join '', 'UPDATE ', $self->word(Model->get($query->from)->table), ' SET ', join(', ', @set), $self->_select($query);
}

# Конструирует delete-запрос SQL
sub sql_delete {
	my ($self, $query) = @_;

	join '', 'DELETE FROM ', $self->word(Model->get($query->from)->table), $self->_select($query);
}

# Превращает в выражение
sub expr {
	my ($self, $expr) = @_;
	
	if($expr->isa(Val)) { $expr->value }
	elsif($expr->isa(Field)) { join '.', $self->word($expr->alias), $self->word(Model->get($expr->entity)->col_name($expr->name)) }
	elsif($expr->isa(UOp)) { join ' ', $expr->op, $self->expr($expr->exp) }
	elsif($expr->isa(Op)) { join $expr->op, $self->expr($expr->left), $self->expr($expr->right) }
	else { die "?" }
}

# Имя поля или таблицы. Экранируется, если попадает в спецсимволы
sub word {
	my ($self, $word) = @_;
	$self->is_keyword($word)? $self->quoteword($word): $word
}

# Ключевое слово?
sub is_keyword {
	my ($self) = @_;
	0
}

# Экранируюет ключевые слова
sub quoteword {
	my ($self, $word) = @_;
	"`$word`"
}

1;