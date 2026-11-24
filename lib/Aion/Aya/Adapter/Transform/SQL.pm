package Aion::Aya::Adapter::Transform::SQL;

use common::sense;

use List::Util qw/pairmap/;

use aliased 'Aion::Aya::Query::Expr::Field';
use aliased 'Aion::Aya::Query::Expr::Op';
use aliased 'Aion::Aya::Query::Expr::UOp';
use aliased 'Aion::Aya::Query::Expr::Val';
use aliased 'Aion::Aya::Model';
use aliased 'Aion::Aya::Query';

use Aion;

extends 'Aion::Aya::Adapter::Transform::Abstract';

# Трансформирует запрос в промежуточное представление DQL или DML
sub transform :Isa(Me => Query => Str) {
	my ($self, $query) = @_;

	given($query->operation) {
		$self->sql_select($query) when Query->SELECT;
		$self->sql_insert($query) when Query->INSERT;
		$self->sql_update($query) when Query->UPDATE;
		$self->sql_delete($query) when Query->DELETE;
	}
}

# Общие части select-запроса: join, where, group by, having, order by, limit, offset
sub _select {
	my ($self, $query) = @_;

	my @join  = map {
		my $feature = Model->get($query->from)->feature($_->field);
		my $ref_class = Model->get_ref($feature);
		if($feature->{opt}{ref}) {
			"\n${\($_->join eq 'inner'? 'INNER': 'LEFT')} JOIN ${\Model->get($ref_class)->table} $_->{alias} ON $_->{alias}.id = ...";
		}
		elsif($feature->{opt}{m2m} || $feature->{opt}{m2n} || $feature->{opt}{n2m} || $feature->{opt}{n2n}) {
			...
		}
		else { die "..." }
	} @{$query->{join}};
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

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Adapter::Transform::SQL - turning Aion::Aya::Query into SQL text (DQL and DML)

=head1 SYNOPSIS

lib/ExEntity.pm file:

	package ExEntity;
	
	use common::sense;
	
	use Aion with => 'Aion::Aya';
	
	presents 'books';
	
	has id => (is => 'ro', isa => PositiveInt, pk => 1);
	has title => (is => 'ro', isa => Str & Len[255], col => 1);
	
	1;

Code:

	use ExEntity;
	
	use aliased 'Aion::Aya::Query';
	use aliased 'Aion::Aya::Adapter::Transform::SQL' => 'TransformSQL';
	
	my $transformator = TransformSQL->new;
	my $query = Query->new(from => 'ExEntity');
	
	$transformator->sql_select($query) # => SELECT * FROM books
	$transformator->sql_delete($query) # => DELETE FROM books

=head1 DESCRIPTION

C<Aion::Aya::Adapter::Transform::SQL> is a specific implementation of the C<Aion::Aya::Adapter::Transform::Abstract> contract: takes C<Aion::Aya::Query> and returns an SQL string for DQL (C<SELECT>) and DML (C<INSERT>, C<UPDATE>, C<DELETE>).

The role differentiates dialects through overridden methods:

=over

=item * C<word> — how to write the table/column name (by default, without escaping);

=item * C<is_keyword> — whether the name is considered a keyword (never by default);

=item * C<quoteword> - how to escape the name if it is a keyword (backtick quotes by default).

=back

C<Aion::Aya::Adapter::Transform::Mem> and C<Aion::Aya::Adapter::Transform::Mysql> inherit SQL and change only the escaping (C<Mysql> escapes with backquotes).

The table and column name are taken from C<Aion::Aya::Model> (C<< Model-E<gt>get($query-E<gt>from)-E<gt>table >> and C<col_name>), so renaming a column in the model does not break SQL.

=head1 SUBROUTINES

=head2 transform ($query)

Turns the query into an SQL string. Dispatches by C<< $query-E<gt>operation >>: C<SELECT> → C<sql_select>, C<INSERT> → C<sql_insert>, C<UPDATE> → C<sql_update>, C<DELETE> → C<sql_delete>.

	my $t = TransformSQL->new;
	my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');
	
	my $select = Query->new(from => 'ExEntity');
	
	$t->sql_select($select) # -> 'SELECT * FROM books'
	
	my $delete = Query->new(from => 'ExEntity');
	
	$t->sql_delete($delete) # -> 'DELETE FROM books'
	
	$t->sql_insert(Query->new(from => 'ExEntity', operation => 'insert', select => [($val, 'title')])) # -> 'INSERT INTO books (title) VALUES (Clarissa)'

=head2 sql_select ($query)

Builds C<SELECT>: C<< SELECT E<lt>fields|*E<gt> FROM [table](https://metacpan.org/pod/table) >> and the common part (see C<_select>). Fields are specified in pairs “expression → alias”.

	my $t = TransformSQL->new;
	my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');
	
	my $query = Query->new(from => 'ExEntity', select => [($val, 'ttl')]);
	
	$t->sql_select($query) # -> 'SELECT Clarissa as ttl FROM books'

=head2 sql_insert ($query)

Builds C<< INSERT INTO [table](https://metacpan.org/pod/table) (E<lt>columnsE<gt>) VALUES (E<lt>valuesE<gt>) >>. The C<select> pairs are the value and name of the column.

	my $t = TransformSQL->new;
	my $val = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');
	
	$t->sql_insert(Query->new(from => 'ExEntity', operation => 'insert', select => [($val, 'title')])) # -> 'INSERT INTO books (title) VALUES (Clarissa)'

=head2 sql_update ($query)

Builds C<UPDATE [table](https://metacpan.org/pod/table) SET [column](https://metacpan.org/pod/column) = [value](https://metacpan.org/pod/value)> and the general part. The C<select> pairs are the value and name of the column.

=head2 sql_delete ($query)

Builds C<DELETE FROM [table](https://metacpan.org/pod/table)> and the general part.

	my $t = TransformSQL->new;
	
	my $query = Query->new(from => 'ExEntity');
	
	$t->sql_delete($query) # -> 'DELETE FROM books'

=head2 _select ($query)

Common tail for all operations: joins, C<WHERE>, C<GROUP BY>, C<HAVING>, C<ORDER BY>, C<LIMIT>, C<OFFSET>.

	my $t = TransformSQL->new;
	my $query = Query->new(from => 'ExEntity', limit => 5, offset => 10);
	
	$t->sql_select($query) # -> 'SELECT * FROM books LIMIT 5 OFFSET 10'

=head2 expr ($expr)

Turns an expression tree node into SQL:

=over

=item * C<Val> — value as is;

=item * C<Field> - C<alias.column>;

=item * C<UOp> - C<op exp> (C<NOT b.title>);

=item * C<Op> — C<left op right> (C<b.title=Clarissa>).

=back

	my $t = TransformSQL->new;
	my $field = Aion::Aya::Query::Expr::Field->new(alias => 'b', name => 'title', entity => 'ExEntity');
	my $val   = Aion::Aya::Query::Expr::Val->new(value => 'Clarissa');
	
	$t->expr($val) # -> 'Clarissa'
	$t->expr($field) # -> 'b.title'
	$t->expr(Aion::Aya::Query::Expr::Op->new(op => '=', left => $field, right => $val)) # -> 'b.title=Clarissa'
	$t->expr(Aion::Aya::Query::Expr::UOp->new(op => 'NOT', exp => $field)) # -> 'NOT b.title'

=head2 word ($word)

Writes the name of a table or column: escapes via C<quoteword> if C<is_keyword> is true, otherwise returns as is.

	my $t = TransformSQL->new;
	
	$t->word('books') # -> 'books'

=head2 is_keyword ($word)

Does the name count as a keyword? In SQL, the default is never; dialect redefines.

	my $t = TransformSQL->new;
	
	$t->is_keyword('books') # -> 0

=head2 quoteword ($word)

Escapes a keyword. In SQL and MySQL - backticks.

	my $t = TransformSQL->new;
	
	$t->quoteword('books') # -> '`books`'

=head1 GOTCHAS

The library is in development, and the SQL dialect currently has limitations:

=over

=item * B<The constructor is not created.> C<< TransformSQL-E<gt>new >> crashes with C<Signature mismatch>: C<transform> in C<SQL> is declared as C<< :Isa(Me =E<gt> Query =E<gt> Str) >>, and the C<Abstract> contract requires C<Any>. Until this is fixed, in the examples the object is created via C<bless>, but C<transform> cannot be called.

=item * B<< C<transform> requires an C<Abstract> object. >> Even with C<bless>, the C<transform> call checks the first argument against the type of C<Abstract> (C<Object['Query']>) and fails if C<Query> does not resolve to the class. That's why the examples show C<sql_*> and C<expr> directly.

=item * B<< C<join> must be a hash for C<_select>. >> C<_select> does C<< %{$query-E<gt>{join}} >>, and C<Aion::Aya::Query> stores C<join> as an array, so C<sql_select> without editing C<< $query-E<gt>{join} = {} >> falls on C<Not a HASH reference>.

=item * B<< C<insert> distinguishes between forms of C<join>. >> C<sql_insert> checks C<< @{$query-E<gt>{join}} >> (array) for C<INSERT ... SELECT> and then calls C<_select> where C<join> needs a hash.

=item * B<< C<filter>/C<having> in C<_select> are checked for truth. >> C<Aion::Aya::Query::Expr::Op> has an overload of C<&{}> without C<bool>, so the expression in C<filter> gives C<Operation "bool": no method found>.

=item * B<< C<ORDER BY> is assembled from pairs. >> C<Aion::Aya::Query> stores C<order_by> as “expression - C<ASC>/C<DESC> pairs”, and C<_select> glues them together through C<pairmap> with the delimiter C<' '>, so the extra delimiter ends up in SQL.

=back

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Adapter::Transform::SQL module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
