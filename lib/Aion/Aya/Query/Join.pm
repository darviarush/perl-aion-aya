package Aion::Aya::Query::Join;
# $qb-><join>_join("<from_alias>.<field> as <to_alias>")
# <join> JOIN <table(model)> <from_alias> ON <from_alias>.<pk(model)> = <to_alias>.<col(field)>
# 
# example:
#   QueryBuilder->new(_from => Project, ...)
#     ->inner_join("user as u")
#     ->left_join("u.role as r")
# 
#   Query->new(model => Project, field => "user", from_alias => "p", to_alias => "u")
#   Query->new(model => User, field => "role", from_alias => "u", to_alias => "r")

use common::sense;

use Aion;

# Тип соединения: inner или left
has join => (is => 'ro+', isa => Enum[qw/inner left/]);

# Класс модели-источника: её поле field (ref) участвует в соединении
has model => (is => 'ro+', isa => ClassName & ConsumerOf['Aion::Aya']);

# Поле исходной модели (ref), по которому идёт соединение
has field => (is => 'ro+', isa => Str);

# Псевдоним исходной таблицы в текущем запросе
has from_alias => (is => 'ro+', isa => Str);

# Псевдоним присоединяемой таблицы
has to_alias => (is => 'ro+', isa => Str);

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Join - соединение с другой таблицей

=head1 SYNOPSIS

	package Storage::Book::Join {
		use Aion with => 'Aion::Aya';
		use Aion::Types;
	
		presents 'books';
	
		has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
		has user => (is => 'ro', isa => Object['Storage::User::Join'], ref => 1);
	}
	
	package Storage::User::Join {
		use Aion with => 'Aion::Aya';
		use Aion::Types;
	
		presents 'users';
	
		has id   => (is => 'ro', isa => Int, pk => 1, col => 1);
		has name => (is => 'ro', isa => Str, col => 1);
	}
	
	use aliased 'Aion::Aya::Query::Join' => 'xJoin';
	
	my $join = xJoin->new(
		join => 'left',
		model => 'Storage::Book::Join',
		field => 'user',
		from_alias => 'b',
		to_alias => 'u',
	);
	
	$join->join       # -> 'left'
	$join->model      # -> 'Storage::Book::Join'
	$join->field      # -> 'user'
	$join->from_alias # -> 'b'
	$join->to_alias   # -> 'u'
	
	my $inner = xJoin->new(join => 'inner', model => 'Storage::Book::Join', field => 'user', from_alias => 'b', to_alias => 'u');
	
	$inner->join # -> 'inner'
	
	# Тип соединения ограничен inner и left
	xJoin->new(join => 'outer', model => 'Storage::Book::Join', field => 'user', from_alias => 'b', to_alias => 'u') # @-> Set feature join must have the type

=head1 DESCRIPTION

C<Join> описывает одно соединение в C<SELECT>. Список соединений хранит C<Aion::Aya::Query> в фиче C<join>.

C<Join> — чистые данные: никакого SQL здесь нет. Как именно выглядит соединение, решает трансформер (SQL, Elastic и т. п.). Из этих данных можно собрать, например, C<LEFT JOIN users u ON u.id = b.user_id>:

=over

=item * C<model> — класс модели-источника, у которой есть C<ref>-поле C<field> (здесь C<Storage::Book::Join::user>);

=item * C<field> — имя этого C<ref>-поля;

=item * C<from_alias> — псевдоним таблицы-источника в текущем запросе (C<b>);

=item * C<to_alias> — псевдоним присоединяемой таблицы (C<u>);

=item * C<join> — тип соединения (C<inner> или C<left>).

=back

Результирующая модель получается из источника: C<< Model-E<gt>get_ref(Model-E<gt>get($join-E<gt>model)-E<gt>feature($join-E<gt>field)) >>. Имя таблицы и имена колонок для C<ON> также получает трансформер.

Класс подключается через C<aliased> под именем C<xJoin>: C<Join> — ещё и тип-функция в C<Aion::Types>, и в пакете с C<use Aion> голое C<< Join-E<gt>new >> распознаётся как вызов прототипа.

Тип соединения ограничен значениями C<inner> и C<left>; любое другое бросает исключение в конструкторе.

=head1 FEATURES

=head2 join

Тип соединения: C<inner> или C<left>.

=head2 model

Класс модели-источника, чьё C<ref>-поле участвует в соединении.

=head2 field

Имя C<ref>-поля в модели C<model>. По нему определяется результирующая модель и колонка источника.

=head2 from_alias

Псевдоним таблицы-источника в текущем запросе.

=head2 to_alias

Псевдоним присоединяемой таблицы.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Join module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

