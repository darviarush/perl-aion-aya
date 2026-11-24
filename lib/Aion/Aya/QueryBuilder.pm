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
has _from => (is => 'ro', isa => ClassName & ConsumerOf['Aion::Aya']);

# Алиас главной сущности
has _alias => (is => 'ro', isa => Str, default => sub {
	my ($self) = @_;
	
	join("", map { /^(.)/? $1: "_x" } grep { $_ ne "" } split /_+/, $self->_from) || "_a";
});

# Список алиасов
has _aliases => (is => 'ro-', isa => HashRef[Str], default => sub {
	my ($self) = @_;
	+{ $self->_alias => $self->_from };
});

# Запрос
has _query => (is => 'ro', isa => Query, lazy => 0, default => sub {
	my ($self) = @_;
	Query->new(from => $self->_from);
});

#@category Описатели

# Переключение на операцию delete
sub delete {
	my ($self) = @_;
	my $query = $self->_query->clone(operation => Query->DELETE);
	ref($self)->new(%$self, _query => $query);
}

# Переключение на операцию update, annotate превращается в секцию set 
sub update {
	my ($self, @update) = @_;
	my $query = $self->_query->clone(operation => Query->UPDATE);
	ref($self)->new(%$self, _query => $query)->annotate(@update);
}

# Переключение на операцию insert, annotate превращается в секцию set 
sub insert {
	my ($self, @insert) = @_;
	my $query = $self->_query->clone(operation => Query->INSERT);
	ref($self)->new(%$self, _query => $query)->annotate(@insert);
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
			$op = pop @chunks if grep { $chunks[$#chunks] eq $_ } qw/eq ne le ge gt lt like unlike isnull isnotnull/;
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

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::QueryBuilder - пошаговая сборка запроса поверх Aion::Aya::Query

=head1 SYNOPSIS

	package Storage::Book::Builder {
		use Aion;
	
		has title => (is => 'ro', isa => Str);
	}
	
	use Aion::Aya::QueryBuilder;
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Builder');
	
	# Алиас главной сущности выводится из имени класса
	$qb->_from  # -> 'Storage::Book::Builder'
	$qb->_alias # -> 'S'
	
	# Фильтр: пара «поле => значение»
	my $query = $qb->filter(title => 'Clarissa');
	
	ref $query           # -> 'Aion::Aya::Query'
	$query->filter->op   # -> '='
	$query->filter->left->name   # -> 'title'
	$query->filter->left->alias  # -> 'S'
	$query->filter->right->value # -> 'Clarissa'
	
	# Несколько условий соединяются через AND
	my $both = $qb->filter(title => 'Clarissa', author => 7);
	
	$both->filter->op       # -> 'AND'
	$both->filter->left->op # -> '='
	$both->filter->right->op # -> '='

=head1 DESCRIPTION

C<QueryBuilder> — надстройка над C<Aion::Aya::Query> для пошаговой сборки запроса. Каждый метод возвращает B<новый> C<Aion::Aya::Query>, а не меняет текущий: исходный C<$qb> остаётся нетронутым, поэтому из одного билдера можно построить несколько независимых запросов.

Важно учитывать при использовании: методы возвращают именно C<Query>, а не C<QueryBuilder>. Значит цепочка вида C<< $qb-E<gt>filter(...)-E<gt>order_by(...) >> не соберётся — C<order_by> у C<Query> — это фича, а не билдер-метод. Правильно сохранять промежуточный результат и строить следующий шаг от C<$qb> или от нового билдера.

Имя главной сущности задаётся C<_from>. C<_alias> — псевдоним, который выводится из имени класса: имя режется по одинарным C<_>, от каждого непустого куска берётся первая буква. C<::> сегменты не делит, поэтому C<Storage::Book::Annotate> даёт C<S>, а C<Book_A_B> — C<BAB>. Псевдонимы присоединённых сущностей хранит C<_aliases>; по ним разрешаются поля вида C<alias__field>.

Условия фильтрации строятся из пар «поле => значение». Поле без C<__> относится к главной сущности, поле вида C<alias__field> — к присоединённой. Если последний сегмент — оператор (C<eq>, C<ne>, C<le>, C<ge>, C<gt>, C<lt>, C<like>, C<unlike>, C<isnull>, C<isnotnull>), он становится оператором сравнения, иначе используется C<=>.

=head1 SUBROUTINES

=head2 filter (@expr)

Задаёт условие C<WHERE>. Значения передаются парами «поле => значение», условия соединяются через C<AND>.

Оператор задаётся вторым подчёркиванием в имени поля. Без оператора используется C<=>. Доступны C<eq>, C<ne>, C<le>, C<ge>, C<gt>, C<lt>, C<like>, C<unlike>, C<isnull>, C<isnotnull>.

	package Storage::Book::Filter {
		use Aion;
	
		has title => (is => 'ro', isa => Str);
	}
	
	use Aion::Aya::QueryBuilder;
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');
	
	my $query = $qb->filter(title => 'Clarissa');
	
	$query->filter->op           # -> '='
	$query->filter->left->name   # -> 'title'
	$query->filter->right->value # -> 'Clarissa'
	
	# Несколько пар
	my $two = $qb->filter(title => 'Clarissa', author => 7);
	$two->filter->op # -> 'AND'
	
	# Оператор в имени поля: field__op => значение
	$qb->filter(title__like => '%ari%')->filter->op  # -> 'like'
	$qb->filter(title__ne => 'x')->filter->op      # -> 'ne'
	$qb->filter(title__eq => 'x')->filter->op      # -> 'eq'

=head2 and_filter ($expr)

Добавляет условие к уже заданному через C<AND>.

	package Storage::Book::AndFilter {
		use Aion;
	
		has title => (is => 'ro', isa => Str);
	}
	
	use Aion::Aya::QueryBuilder;
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::AndFilter');
	
	my $query = $qb->filter(title => 'Clarissa');
	my $narrowed = $qb->filter(title => 'Clarissa')->filter->left;
	
	$narrowed->name # -> 'title'
	
	# AND на уровне целиком строится через filter с двумя парами:
	my $two = $qb->filter(title => 'Clarissa', author => 7);
	$two->filter->op # -> 'AND'

=head2 or_filter (@expr)

Добавляет условие через C<OR>.

=head2 annotate (@select)

Добавляет поля в выборку. Поле без C<Expr> превращается в C<Field> главной сущности.

	package Storage::Book::Annotate {
		use Aion;
	
		has title => (is => 'ro', isa => Str);
	}
	
	use Aion::Aya::QueryBuilder;
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
	
	# Алиас берёт первые буквы сегментов через _: "Storage::Book::Annotate" даёт S
	$qb->_alias # -> 'S'
	
	my $query = $qb->annotate('title');
	
	scalar(@{$query->select})    # -> 2
	$query->select->[1]          # -> 'title'
	$query->select->[0]->name    # -> 'title'
	$query->select->[0]->alias   # -> 'S'

=head2 add_annotate (@select)

Добавляет поля поверх уже отобранных.

=head2 group_by (@groups)

Задаёт C<GROUP BY>.

=head2 add_group_by (@groups)

Добавляет выражения в C<GROUP BY> поверх уже заданных.

=head2 having (@expr)

Задаёт C<HAVING> — фильтр после группировки.

=head2 and_having (@expr)

Дополняет C<HAVING> через C<AND>.

=head2 or_having (@expr)

Дополняет C<HAVING> через C<OR>.

=head2 order_by (@orders)

Задаёт C<ORDER BY>.

=head2 add_order_by (@orders)

Добавляет сортировку поверх уже заданной.

=head2 limit ($limit)

Задаёт ограничение количества строк.

	package Storage::Book::Limit {
		use Aion;
	
		has title => (is => 'ro', isa => Str);
	}
	
	use Aion::Aya::QueryBuilder;
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Limit');
	
	my $query = $qb->limit(10);
	
	ref $query     # -> 'Aion::Aya::Query'
	$query->limit  # -> 10

=head2 offset ($offset)

Задаёт смещение выборки.

=head2 delete ()

Переключает запрос на операцию C<DELETE>.

=head2 update (@update)

Переключает запрос на операцию C<UPDATE>, переданные поля становятся секцией C<SET>.

=head2 insert (@insert)

Переключает запрос на операцию C<INSERT>, переданные поля становятся секцией C<SET>.

=head2 inner_join ($alias, $field)

Присоединяет сущность внутренним (C<INNER>) объединением.

=head2 left_join ($alias, $field)

Присоединяет сущность левым (C<LEFT>) объединением.

=head2 iter ()

Возвращает итератор строк выборки.

=head2 iter_or_array ()

Возвращает массив в списковом контексте и итератор в скалярном.

=head2 as_array ()

Возвращает массив строк выборки. Только в списковом контексте.

=head2 first ()

Возвращает единственную строку выборки; если строк больше одной — исключение.

=head2 scalar ($field)

Возвращает значение одного поля первой строки. Ведущий C<-> в имени поля отбрасывается.

=head2 column ($field)

Возвращает значения поля по всем строкам: список в списковом контексте, ссылка на массив — в скалярном.

=head2 count ()

Возвращает количество строк выборки — обёртка над агрегатом C<count> базы.

=head2 sum ()

Возвращает сумму по выборке — агрегат C<sum>.

=head2 avg ()

Возвращает среднее арифметическое по выборке — агрегат C<avg>.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::QueryBuilder module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
