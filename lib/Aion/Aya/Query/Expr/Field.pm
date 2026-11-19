package Aion::Aya::Query::Expr::Field;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

has alias => (is => 'ro', isa => Str);
has name => (is => 'ro', isa => Str);
has entity => (is => 'ro', isa => ClassName);

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Expr::Field - ссылка на столбец таблицы в выражении

=head1 SYNOPSIS

	package Storage::Book {
		use Aion;
	
		has title => (is => 'ro', isa => Str);
	}
	
	use Aion::Aya::Query::Expr::Field;
	
	my $field = Aion::Aya::Query::Expr::Field->new(
		alias => 'b',
		name => 'title',
		entity => 'Storage::Book',
	);
	
	$field->alias   # -> 'b'
	$field->name    # -> 'title'
	$field->entity  # -> 'Storage::Book'
	$field->isa('Aion::Aya::Query::Expr') # -> 1

=head1 DESCRIPTION

C<Field> — лист дерева выражений, который ссылается на столбец сущности. В SQL превращается в C<alias.column>.

Поле задаётся тройкой:

=over

=item * C<entity> — класс сущности (по нему C<Aion::Aya::Model> находит имя таблицы и столбца);

=item * C<name> — имя фичи сущности (не колонки);

=item * C<alias> — псевдоним таблицы в запросе.

=back

По C<entity> и C<name> диалект получает настоящее имя столбца через C<< Model-E<gt>col_name >>, поэтому переименование колонки в модели не ломает запросы.

=head1 FEATURES

=head2 alias

Псевдоним таблицы в запросе (C<b> в C<b.title>).

=head2 name

Имя фичи сущности (свойства C<has>), а не имя столбца.

=head2 entity

Класс сущности, которой принадлежит поле.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Expr::Field module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
