package Aion::Aya::QueryBuilder;
# Заполняет Query

use common::sense;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Query::Expr';
use aliased 'Aion::Aya::Query::Expr::Field';
use aliased 'Aion::Aya::Query::Expr::Op';
use aliased 'Aion::Aya::Query::Expr::Val';
use aliased 'Aion::Aya::Query::Join' => 'xJoin';
use aliased 'Aion::Aya::Model';
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

#@category Клонирование

# Клонирует QueryBuilder: Query клонируется отдельно, алиасы копируются
sub clone {
	my ($self, %opt) = @_;

	my $self_opt = $opt{self} // {};
	my $aliases = { %{$self->_aliases}, %{$opt{aliases} // {}} };

	bless {
		%$self,
		%$self_opt,
		_aliases => $aliases,
		_query => $self->_query->clone(%{$opt{_query} // {}}),
	}, ref $self;
}

#@category Описатели

# Переключение на операцию delete
sub delete {
	my ($self) = @_;
	$self->clone(_query => {operation => Query->DELETE});
}

# Переключение на операцию update, annotate превращается в секцию set 
sub update {
	my ($self, @update) = @_;
	$self->clone(_query => {operation => Query->UPDATE})->annotate(@update);
}

# Переключение на операцию insert, annotate превращается в секцию set 
sub insert {
	my ($self, @insert) = @_;
	$self->clone(_query => {operation => Query->INSERT})->annotate(@insert);
}

# Присоединяет другую сущность внутренним (inner) объединением. Допустимые формы — см. _make_join
sub inner_join {
	my ($self, @join) = @_;

	$self->_make_join('inner', @join);
}

# Присоединяет другую сущность левым (left) объединением. Допустимые формы — см. _make_join
sub left_join {
	my ($self, @join) = @_;

	$self->_make_join('left', @join);
}

# Разбирает описание объединения и добавляет его в запрос клона.
# Формы:
#   'user as u'         — поле user главной сущности, алиас u
#   user => -u          — то же, тире у алиаса отбрасывается
#   'u.admin as a'      — поле admin из уже присоединенного алиаса u, алиас a
#   u__admin => -a      — то же в виде "алиас__поле => алиас"
sub _make_join {
	my ($self, $type, @join) = @_;

	my ($field, $alias);

	# Строковая форма: '<field> as <alias>' (один аргумент)
	if (@join == 1) {
		$join[0] =~ /^\s*(.+?)(?:\s+as\s+([\w\-]+))?\s*$/i
			or die "Bad join description: $join[0]";
		($field, $alias) = ($1, $2);
	}
	# Парная форма: field => alias
	else {
		die 'Join expects a pair <field => alias>' if @join != 2;
		($field, $alias) = @join;
	}

	$alias =~ s/^-// if defined $alias;
	$alias //= $self->_alias;

	# field может быть 'u.admin' или 'u__admin' — алиас-источник и имя поля
	my ($from_alias, $name) = $field =~ /^([^._]+)(?:\.|__)(.+)$/
		? ($1, $2)
		: ($self->_alias, $field);

	die "Unknown alias '$from_alias' in join '$field'"
		unless exists $self->_aliases->{$from_alias} || $from_alias eq $self->_alias;

	# Поле должно быть ref: по нему строится соединение
	my %models = map { $_ => Model->get($self->_aliases->{$_}) } keys %{$self->_aliases};
	my $feature = $models{$from_alias}->{field}{$name}
		or die "Not $name field of $self->_aliases->{$from_alias}";

	die "Field $self->_aliases->{$from_alias}\::$name is not a ref!" unless $feature->{type} eq 'ref';

	my ($ref_class) = @{$feature->{ref}};

	$self->clone(
		_query => { join => [ @{$self->_query->join}, xJoin->new(
			join => $type,
			model => $self->_aliases->{$from_alias},
			field => $name,
			from_alias => $from_alias,
			to_alias => $alias,
		) ] },
		aliases => { $alias => $ref_class },
	);
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

	$self->clone(_query => {select => \@out});
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
	$self->clone(_query => {filter => $op});
}

# Дополняет условие фильтрации логическим И (AND)
sub and_filter {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	my $old = $self->_query->filter;
	$self->clone(_query => {filter => defined $old? Op->new(left => $old, op => 'AND', right => $op): $op});
}

# Дополняет условие фильтрации логическим ИЛИ (OR)
sub or_filter {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	my $old = $self->_query->filter;
	$self->clone(_query => {filter => defined $old? Op->new(left => $old, op => 'OR', right => $op): $op});
}

# Задаёт группировку
sub group_by {
	my ($self, @groups) = @_;
	$self->clone(_query => {group_by => \@groups});
}

# Добавляет поля в группировку поверх уже заданных
sub add_group_by {
	my ($self, @groups) = @_;
	$self->clone(_query => {group_by => [@{$self->_query->group_by}, @groups]});
}

# Задаёт условие фильтрации после группировки (HAVING)
sub having {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	$self->clone(_query => {having => $op});
}

# Дополняет условие HAVING логическим И (AND)
sub and_having {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	my $old = $self->_query->having;
	$self->clone(_query => {having => defined $old? Op->new(left => $old, op => 'AND', right => $op): $op});
}

# Дополняет условие HAVING логическим ИЛИ (OR)
sub or_having {
	my ($self, @expr) = @_;
	my $op = $self->_plain_op(@expr);
	my $old = $self->_query->having;
	$self->clone(_query => {having => defined $old? Op->new(left => $old, op => 'OR', right => $op): $op});
}

# Задаёт сортировку
sub order_by {
	my ($self, @orders) = @_;
	$self->clone(_query => {order_by => \@orders});
}

# Добавляет сортировку поверх уже заданной
sub add_order_by {
	my ($self, @orders) = @_;
	$self->clone(_query => {order_by => [@{$self->_query->order_by}, @orders]});
}

# Задаёт смещение выборки
sub offset {
	my ($self, $offset) = @_;
	$self->clone(_query => {offset => $offset});
}

# Задаёт ограничение количества строк
sub limit {
	my ($self, $limit) = @_;
	$self->clone(_query => {limit => $limit});
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
		use Aion with => 'Aion::Aya';
		use Aion::Types;
	
		presents 'books';
	
		has id    => (is => 'ro', isa => Int, pk => 1, col => 1);
		has title => (is => 'ro', isa => Str, col => 1);
	}
	
	use Aion::Aya::QueryBuilder;
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Builder');
	
	# Алиас главной сущности выводится из имени класса
	$qb->_from  # -> 'Storage::Book::Builder'
	$qb->_alias # -> 'S'
	
	# Каждый шаг возвращает новый QueryBuilder — можно строить цепочку
	my $query = $qb->filter(title => 'Clarissa')->limit(10);
	
	ref $query                    # -> 'Aion::Aya::QueryBuilder'
	$query->_query->filter->op    # -> '='
	$query->_query->filter->left->name   # -> 'title'
	$query->_query->filter->left->alias  # -> 'S'
	$query->_query->filter->right->value # -> 'Clarissa'
	$query->_query->{limit}       # -> 10
	
	# Исходный билдер не изменяется
	$qb->_query->{limit} # -> undef

=head1 DESCRIPTION

C<QueryBuilder> — надстройка над C<Aion::Aya::Query> для пошаговой сборки запроса. Каждый метод возвращает B<< новый C<QueryBuilder> >> (через C<clone>), а не меняет текущий и не возвращает голый C<Query>. Поэтому шаги можно объединять в цепочку: C<< $qb-E<gt>filter(...)-E<gt>limit(10)-E<gt>offset(5) >>, а исходный C<$qb> остаётся нетронутым.

Сам запрос доступен у результата в фиче C<_query>. Имя главной сущности задаётся C<_from>; C<_alias> — псевдоним, выводимый из имени класса: имя режется по одинарным C<_>, от каждого непустого куска берётся первая буква. C<::> сегменты не делит, поэтому C<Storage::Book::Builder> даёт C<S>, а C<Book_A_B> — C<BAB>. Псевдонимы присоединённых сущностей хранит C<_aliases>.

Условия фильтрации строятся из пар «поле => значение». Поле без C<__>/C<.> относится к главной сущности, поле вида C<alias__field>/C<alias.field> — к присоединённой. Если последний сегмент — оператор (C<eq>, C<ne>, C<le>, C<ge>, C<gt>, C<lt>, C<like>, C<unlike>, C<isnull>, C<isnotnull>), он становится оператором сравнения, иначе используется C<=>.

=head1 SUBROUTINES

=head2 clone (%opt)

Клонирует билдер: запрос клонируется отдельно, алиасы копируются в новый хеш. Опции:

=over

=item * C<_query> — изменения для C<< Query-E<gt>clone >> (C<< { operation =E<gt> ..., limit =E<gt> ... } >>);

=item * C<aliases> — добавляемые/переопределяемые алиасы;

=item * C<self> — произвольные изменения самого билдера.

=back

	package Storage::Book::Clone {
		use Aion with => 'Aion::Aya';
		use Aion::Types;
	
		presents 'books';
	
		has title => (is => 'ro', isa => Str, col => 1);
	}
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Clone');
	
	my $copy = $qb->clone(_query => { limit => 5 });
	
	ref $copy               # -> 'Aion::Aya::QueryBuilder'
	$copy->_query->{limit}  # -> 5
	$qb->_query->{limit}    # -> undef

=head2 filter (@expr)

Задаёт условие C<WHERE> из пар «поле => значение»; пары соединяются через C<AND>. Оператор задаётся вторым C<__> в имени поля.

	package Storage::Book::Filter {
		use Aion with => 'Aion::Aya';
		use Aion::Types;
	
		presents 'books';
	
		has title => (is => 'ro', isa => Str, col => 1);
	}
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');
	
	my $query = $qb->filter(title => 'Clarissa');
	
	$query->_query->filter->op           # -> '='
	$query->_query->filter->left->name   # -> 'title'
	$query->_query->filter->right->value # -> 'Clarissa'
	
	my $two = $qb->filter(title => 'Clarissa', title => 7);
	$two->_query->filter->op # -> 'AND'
	
	$qb->filter(title__like => '%ari%')->_query->filter->op # -> 'like'
	$qb->filter(title__ne => 'x')->_query->filter->op       # -> 'ne'

=head2 and_filter (@expr)

Добавляет условие через C<AND>. Если предыдущего условия нет, ставит новое без C<AND>.

	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');
	
	$qb->and_filter(title => 'x')->_query->filter->op # -> '='
	
	my $narrowed = $qb->filter(title => 'x')->and_filter(title => 'y');
	
	$narrowed->_query->filter->op       # -> 'AND'
	$narrowed->_query->filter->left->op # -> '='

=head2 or_filter (@expr)

Добавляет условие через C<OR>. Если предыдущего условия нет, ставит новое без C<OR>.

	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Filter');
	
	$qb->or_filter(title => 'x')->_query->filter->op # -> '='
	
	$qb->filter(title => 'x')->or_filter(title => 'y')->_query->filter->op # -> 'OR'

=head2 annotate (@select)

Добавляет поля в выборку: C<< Expr =E<gt> Str >> или просто имя поля (превращается в поле главной сущности).

	package Storage::Book::Annotate {
		use Aion with => 'Aion::Aya';
		use Aion::Types;
	
		presents 'books';
	
		has title => (is => 'ro', isa => Str, col => 1);
	}
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
	
	my $query = $qb->annotate('title');
	
	scalar(@{$query->_query->select})    # -> 2
	$query->_query->select->[1]          # -> 'title'
	$query->_query->select->[0]->name    # -> 'title'
	$query->_query->select->[0]->alias   # -> 'S'

=head2 add_annotate (@select)

Добавляет поля поверх уже отобранных.

	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
	
	my $query = $qb->annotate('title')->add_annotate('id');
	
	scalar(@{$query->_query->select}) # -> 4

=head2 group_by (@groups)

Задаёт C<GROUP BY>.

=head2 add_group_by (@groups)

Добавляет выражения в C<GROUP BY> поверх уже заданных.

	use aliased 'Aion::Aya::Query::Expr::Field';
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
	my $t = Field->new(alias => 'S', name => 'title', entity => 'Storage::Book::Annotate');
	
	my $query = $qb->group_by($t)->add_group_by($t);
	
	scalar(@{$query->_query->group_by}) # -> 2

=head2 having (@expr)

Задаёт C<HAVING> — фильтр после группировки.

=head2 and_having (@expr)

Дополняет C<HAVING> через C<AND>.

=head2 or_having (@expr)

Дополняет C<HAVING> через C<OR>.

	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
	
	$qb->having(title => 'x')->_query->having->op # -> '='
	$qb->having(title => 'x')->and_having(title => 'y')->_query->having->op # -> 'AND'

=head2 order_by (@orders)

Задаёт C<ORDER BY>. Значения — пары «выражение/поле => C<ASC>|C<DESC>».

=head2 add_order_by (@orders)

Добавляет сортировку поверх уже заданной.

	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
	my $t = Field->new(alias => 'S', name => 'title', entity => 'Storage::Book::Annotate');
	
	my $query = $qb->order_by($t => 'ASC')->add_order_by($t => 'DESC');
	
	scalar(@{$query->_query->order_by}) # -> 4

=head2 offset ($offset)

Задаёт смещение выборки.

=head2 limit ($limit)

Задаёт ограничение количества строк.

	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Annotate');
	
	my $query = $qb->limit(10)->offset(2);
	
	$query->_query->{limit}  # -> 10
	$query->_query->{offset} # -> 2

=head2 delete ()

Переключает запрос на операцию C<DELETE>.

=head2 update (@update)

Переключает запрос на C<UPDATE>, переданные поля становятся секцией C<SET>.

=head2 insert (@insert)

Переключает запрос на C<INSERT>, переданные поля становятся секцией C<SET>.

=head2 inner_join ($field, $alias)

Присоединяет сущность внутренним (C<INNER>) объединением.

=head2 left_join ($field, $alias)

Присоединяет сущность левым (C<LEFT>) объединением.

Оба метода разбирают описание через общий C<_make_join> и поддерживают формы:

=over

=item * C<'user as u'> — поле C<user> B<главной> сущности, алиас C<u>;

=item * C<< user =E<gt> 'u' >> — то же; у алиаса отбрасывается ведущее C<-> (C<< user =E<gt> '-u' >>);

=item * C<'u.admin as a'> — поле C<admin> уже присоединённого алиаса C<u>, алиас C<a>;

=item * C<< u__admin =E<gt> 'a' >> — то же в форме «алиас__поле => алиас».

=back

Поле должно быть объявлено как C<ref>; в C<Join> кладётся модель-источник и её C<ref>-поле. Имя таблицы и колонки для C<ON> получает трансформер.

	package Storage::Book::Join {
		use Aion with => 'Aion::Aya';
		use Aion::Types;
	
		presents 'books';
	
		has id      => (is => 'ro', isa => Int, pk => 1, col => 1);
		has user    => (is => 'ro', isa => Object['Storage::User::Join'], ref => 1);
	}
	
	package Storage::User::Join {
		use Aion with => 'Aion::Aya';
		use Aion::Types;
	
		presents 'users';
	
		has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
		has name => (is => 'ro', isa => Str, col => 1);
	}
	
	my $qb = Aion::Aya::QueryBuilder->new(_from => 'Storage::Book::Join');
	
	my $joined = $qb->left_join('user as u');
	my $join = $joined->_query->join->[0];
	
	$join->join       # -> 'left'
	$join->model      # -> 'Storage::Book::Join'
	$join->field      # -> 'user'
	$join->from_alias # -> 'S'
	$join->to_alias   # -> 'u'
	
	# Новый алиас регистрируется, по нему можно присоединять дальше
	$joined->_aliases->{u} # -> 'Storage::User::Join'
	
	# Парная форма, тире отбрасывается
	my $inner = $qb->inner_join(user => '-u');
	$inner->_query->join->[0]->to_alias # -> 'u'
	$inner->_query->join->[0]->join     # -> 'inner'
	
	# Неизвестное поле
	$qb->inner_join('zzz as a') # @-> Not zzz field

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
