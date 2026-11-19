package Aion::Aya::Query::Order;

use common::sense;

use Aion;

has desc => (is => 'ro', isa => Bool);

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Order - направление сортировки

=head1 SYNOPSIS

	use Aion::Aya::Query::Order;
	
	my $order = Aion::Aya::Query::Order->new(desc => 1);
	
	$order->desc # -> 1
	
	my $asc = Aion::Aya::Query::Order->new;
	
	$asc->desc # -> undef

=head1 DESCRIPTION

C<Order> указывает направление сортировки: по возрастанию (C<desc> ложно) или по убыванию (C<desc> истинно).

Сейчас C<Aion::Aya::Query> хранит сортировки как пары «выражение — строка C<ASC>/C<DESC>», а C<Order> — задел на замену строки объектом. Используйте C<Order>, если нужен объектный вид направления без привязки к диалекту.

=head1 FEATURES

=head2 desc

Сортировка по убыванию.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Order module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
