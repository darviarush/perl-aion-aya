# NAME

Aion::Aya::Query - запрос к базе (DQL): выборка, условия, соединения, сортировка и пагинация

# SYNOPSIS

```perl
package Storage::Book::Synopsis {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::Query;
use aliased 'Aion::Aya::Query::Join' => 'xJoin';

my $query = Aion::Aya::Query->new(
	from => 'Storage::Book::Synopsis',
	select => [],
	join => [xJoin->new(field => 'author', alias => 'a', join => 'left')],
	group_by => [],
	having => undef,
	order_by => [],
	offset => 20,
	limit => 10,
);

$query->operation                   # -> 'select'
$query->from                        # -> 'Storage::Book::Synopsis'
scalar(@{$query->select})              # -> 0
$query->join->[0]->{alias}          # -> 'a'
$query->join->[0]->{join}           # -> 'left'
scalar(@{$query->group_by})            # -> 0
$query->having                      # -> undef
scalar(@{$query->order_by})            # -> 0
$query->offset                      # -> 20
$query->limit                       # -> 10
$query->filter                      # -> undef

# Обязателен только from; остальное по умолчанию пусто
my $empty = Aion::Aya::Query->new(from => 'Storage::Book::Synopsis');

scalar(@{$empty->select})   # -> 0
scalar(@{$empty->join})     # -> 0
scalar(@{$empty->order_by}) # -> 0
$empty->limit               # -> undef

Aion::Aya::Query->new # @-> from required
```

# DESCRIPTION

`Aion::Aya::Query` — объектное представление запроса. Модуль ничего не знает о базе: он только хранит части запроса. Запрос можно собрать, склонировать и дополнить, а затем передать адаптеру — тот отдаст `Aion::Aya::Iterator` или число затронутых строк.

Операция по умолчанию — `select`. Остальные операции (`insert`, `update`, `delete`) используются `Aion::Aya::Box` и `Aion::Aya::Appearance` при записи.

Обязателен только `from`; остальные части по умолчанию пусты.

# SUBROUTINES

## clone ()

Создаёт независимую копию запроса: изменения в копии не затрагивают оригинал.

```perl
package Storage::Book::Clone {
	use Aion;

	has title => (is => 'ro', isa => Str);
}

use Aion::Aya::Query;

my $query = Aion::Aya::Query->new(from => 'Storage::Book::Clone', limit => 10);

my $copy = $query->clone(limit => 25);

ref $copy      # -> 'Aion::Aya::Query'
$copy->from    # -> 'Storage::Book::Clone'
$query->limit  # -> 10
$copy->limit   # -> 25

my $copy2 = $copy->clone(limit => 30);
$copy2->limit  # -> 30
$copy->limit   # -> 25
$query->limit  # -> 10
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Query module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
