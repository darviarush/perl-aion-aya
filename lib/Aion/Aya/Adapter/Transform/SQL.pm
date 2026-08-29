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

# Конструирует select-запрос SQL
sub sql_select {
	my ($self, $query) = @_;

	my @fields = pairmap {($self->expr($a), ' as ', $self->word($b))} @{$query->{select}};

	my @join = map {"\nJOIN "} %{$query->{join}};
	
	join "", 'SELECT ', @fields? @fields: '*', ' FROM', @join;
}

# Превращает в выражение
sub expr {
	my ($self, $expr) = @_;
	
	if($expr->isa(Val)) { $expr->value }
	elsif($expr->isa(Field)) { join '.', $self->word($expr->alias), $self->word(Model->get($expr->from)->col_name($expr->name)) }
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