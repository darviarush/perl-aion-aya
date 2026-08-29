package Aion::Aya::QueryBuilder;
# Заполняет Query

use common::sense;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Query::Expr';
use aliased 'Aion::Aya::Query::Expr::Field';
use aliased 'Aion::Aya::Query::Expr::Op';
use aliased 'Aion::Aya::Query::Expr::Val';
use aliased 'Aion::Aya::Iterator';

use List::Util qw/pairmap reduce/;

use Aion;

# Управляющий сущностями
has _appearance => (is => 'ro', isa => 'Aion::Aya::Appearance');

# Класс главной сущности
has _from => (is => 'ro', isa => ClassName);

# Алиас главной сущности
has _alias => (is => 'ro', isa => Str, default => sub {
	my ($self) = @_;
	
	join("", map { /^(.)/? $1: "_x" } grep { $_ ne "" } split /_+/, $self->_from) || "_a";
});

# Список алиасов
has _aliases => (is => 'ro-', isa => HashRef[Str], default => sub {
	my ($self) = @_;
	+{ $self->_alias => $self->_from }
});

# Запрос
has _query => (is => 'ro-', isa => Query, lazy => 0, defalt => sub { Query->new(from => $self->_from) });

#@category Описатели

# Переключение на операцию delete
sub delete {
	my ($self) = @_;
	$self->_query->clone(operation => Query->DELETE);
}

# Переключение на операцию update, annotate превращается в секцию set 
sub update {
	my ($self, @update) = @_;
	$self->_query->clone(operation => Query->UPDATE)->annotate(@update);
}

# Переключение на операцию insert, annotate превращается в секцию set 
sub insert {
	my ($self, @insert) = @_;
	$self->_query->clone(operation => Query->INSERT)->annotate(@insert);
}

# Присоединяет другую сущность внутренним (inner) объединением
sub inner_join {
	my ($self, $alias, $field) = @_;
	$self->_query->clone(join => +{ @{$self->_query->join}, xJoin->new(field => $field, alias => $alias, join => 'inner') });
}

# Присоединяет другую сущность левым (left) объединением
sub left_join {
	my ($self, $alias, $field) = @_;
	$self->_query->clone(join => +{ @{$self->_query->join}, xJoin->new(field => $field, alias => $alias, join => 'left') });
}

# Добавляет поля, которые или есть в объекте и их нужно подтянуть или которые будут добавлены в PROXY-объект.
# Это или 'Expr' => Str (выражение, а за ним название поля) или Str – поле
sub annotate {
	my ($self, @select) = @_;

	my @out;
	while (@select) {
		my $item = shift @select;
		if (UNIVERSAL::isa($item, Expr)) {
			my $name = shift @select;
			die "Expect a Str name after Expr!" if UNIVERSAL::isa($name, Expr);
			push @out, $item, $name;
		} else {
			push @out, Field->new(alias => $self->_alias, name => $item, entity => $self->_from), $item;
		}
	}

	$self->_query->clone(select => \@out);
}

# Добавляет поля в выборку поверх уже отобранных
sub add_annotate {
	my ($self, @select) = @_;
	$self->annotate(@{$self->_query->select}, @select);
}

# Задаёт условие фильтрации
sub filter {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	$self->_query->clone(filter => $op);
}

# Дополняет условие фильтрации логическим И (AND)
sub and_filter {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	$self->_query->clone(filter => Op->new(left => $self->filter, op => 'AND', right => $op));
}

# Дополняет условие фильтрации логическим ИЛИ (OR)
sub or_filter {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	$self->_query->clone(filter => Op->new(left => $self->filter, op => 'OR', right => $op));
}

# Задаёт группировку
sub group_by {
	my ($self, @groups) = @_;
	$self->_query->clone(group_by => \@groups);
}

# Добавляет поля в группировку поверх уже заданных
sub add_group_by {
	my ($self, @groups) = @_;
	$self->_query->clone(group_by => [@{$self->_group_by}, @groups]);
}

# Задаёт условие фильтрации после группировки (HAVING)
sub having {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	$self->_query->clone(having => $op);
}

# Дополняет условие HAVING логическим И (AND)
sub and_having {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	$self->_query->clone(having => Op->new(left => $self->having, op => 'AND', right => $op));
}

# Дополняет условие HAVING логическим ИЛИ (OR)
sub or_having {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	$self->_query->clone(having => Op->new(left => $self->having, op => 'OR', right => $op));
}

# Задаёт сортировку
sub order_by {
	my ($self, @orders) = @_;
	$self->_query->clone(order_by => \@orders);
}

# Добавляет сортировку поверх уже заданной
sub add_order_by {
	my ($self, @orders) = @_;
	$self->_query->clone(order_by => [@{$self->order_by}, @orders]);
}

# Задаёт смещение выборки
sub offset {
	my ($self, $offset) = @_;
	 $self->_query->clone(offset => $offset);
}

# Задаёт ограничение количества строк
sub limit {
	my ($self, $limit) = @_;
	 $self->_query->clone(limit => $limit);
}

#@category Получатели

# Возвращает итератор по строкам выборки
sub iter {
	my ($self) = @_;
	
	$self->adapter->iterator;
}

# Возвращает массив в списковом контексте или итератор в скалярном
sub iter_or_array {
	my ($self) = @_;
	wantarray? $self->as_array: $self->iter;
}

# Возвращает массив строк выборки
sub as_array {
	my ($self) = @_;
	die "Not array context!" unless wantarray;
	@{$self->iter};
}

# Возвращает единственную строку выборки (или умирает, если строк много)
sub first {
	my ($self) = @_;
	my $iter = $self->iter;
	my $first = $iter->next;
	die "Many rows!" if defined $iter->next;
	$first
}

# Возвращает значение поля единственной строки выборки
sub scalar {
	my ($self, $field) = @_;
	$field =~ s/^-//;
	$self->first->$field;
}

# Возвращает список значений поля всех строк выборки
sub column {
	my ($self, $field) = @_;
	$field =~ s/^-//;
	my $iter = $self->iter;
	my @column;
	push @column, $_->$field while <$iter>;
	wantarray? @column: \@column;
}

# Возвращает число строк в выборке
sub count {
	my ($self) = @_;
	$self->annotate(Fn->new(name => 'count') => -count)->scalar(-count);
}

# Возвращает сумму значений по выборке
sub sum {
	my ($self) = @_;
	$self->annotate(Fn->new(name => 'sum') => -sum)->scalar(-sum);
}

# Возвращает среднее арифметическое по выборке
sub avg {
	my ($self) = @_;
	$self->annotate(Fn->new(name => 'avg') => -avg)->scalar(-avg);
}

#@category Утилиты

# Производит из списка в filter или having Expr
sub _plain_op {
	my ($self, @expr) = @_;
	return $expr[0] if @expr == 1;

	reduce { $a & $b } pairmap {
		my $op = '=';
		my $left = UNIVERSAL::isa($a, Expr)? $a: do {
			my @chunks = split /__/, $a;
			$op = pop @chunks if $chunks[$#chunks] ~~ qw/eq ne le ge gt lt like unlike isnull isnotnull/;
			die "Not field `$a`" if @chunks < 1;
			die "Many chunks `$a`" if @chunks > 2;
			my ($alias, $entity, $name) = @chunks == 1
				? ($self->_alias, $self->_from, $chunks[0])
				: ($chunks[0], $self->_aliases->{$chunks[0]}, $chunks[1]);
			Field->new(alias => $alias, name => $name, entity => $entity);
		};

		my $right = UNIVERSAL::isa($b, Expr)? $b: Val->new(value => $b);
		
		Op->new(left => $left, op => $op, right => $right);
	} @expr;
}

1;