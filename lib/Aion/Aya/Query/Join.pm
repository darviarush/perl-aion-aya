package Aion::Aya::Query::Join;

use common::sense;

use Aion;

has field => (is => 'ro', isa => Str);
has alias => (is => 'ro', isa => Str);
has join => (is => 'ro', isa => Enum[qw/inner left/]);

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Join - соединение с другой таблицей

=head1 SYNOPSIS

	use aliased 'Aion::Aya::Query::Join' => 'xJoin';
	
	my $join = xJoin->new(field => 'author', alias => 'a', join => 'left');
	
	$join->field # -> 'author'
	$join->alias # -> 'a'
	$join->join  # -> 'left'
	
	my $inner = xJoin->new(field => 'author', alias => 'a', join => 'inner');
	
	$inner->join # -> 'inner'
	
	# Тип соединения ограничен inner и left
	xJoin->new(field => 'author', alias => 'a', join => 'outer') # @-> Set feature join must have the type

=head1 DESCRIPTION

C<Join> описывает, с какой таблицей и как соединяться в C<SELECT>. Список соединений хранит C<Aion::Aya::Query> в фиче C<join>.

Класс подключается через C<aliased> под именем C<xJoin>: C<Join> — ещё и тип-функция в C<Aion::Types>, и в пакете с C<use Aion> голое C<< Join-E<gt>new >> распознаётся как вызов прототипа.

Тип соединения ограничен значениями C<inner> и C<left>; любое другое бросает исключение в конструкторе.

=head1 FEATURES

=head2 field

Поле сущности, по которому идёт соединение.

=head2 alias

Псевдоним присоединяемой таблицы.

=head2 join

Тип соединения: C<inner> или C<left>.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Join module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
