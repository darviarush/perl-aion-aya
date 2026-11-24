!ru:en
# NAME

Aion::Aya::Iterator - курсор по строкам результата запроса с перегрузками для удобного перебора

# SYNOPSIS

```perl
package Adapter::Mock {
	our @ISA = 'Aion::Aya::Adapter';

	sub new { bless {}, shift }

	sub next { my ($self, $session) = @_; $session->{rows}[$session->{i}++] }
}

use Aion::Aya::Iterator;

Aion::Aya::Iterator->Aion::initialize;

my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [1, 2, 3]});

$iterator->next # -> 1
$iterator->next # -> 2
$iterator->next # -> 3
$iterator->next # -> undef
```

# DESCRIPTION

`Aion::Aya::Iterator` — тонкая обёртка над **сессией** адаптера. Сам итератор ничего не знает о базе: он хранит `adapter` и `session`, а всю работу делает адаптер.

`session` для адаптера на `DBI` (`Aion::Aya::Adapter::Iterator::DBI`) — это хеш, который адаптер наполняет лениво, по мере вызовов `next`:

- `query` — объект `Aion::Aya::Query`, из которого трансформатор делает SQL (для `iterator`);
- `sql` — готовый SQL (для `raw_iterator`);
- `dbh` — соединение, берётся из пула адаптера или открывается заново;
- `sth` — подготовленный и запущенный запрос; когда строки кончились, `sth` и `dbh` из сессии удаляются и возвращаются в пул.

Поэтому итератор — это **одноразовый курсор**: сессия продвигается вперёд, а вернуться к уже прочитанным строкам нельзя.

`Iterator` перегружает три операции:

- **`@{ }`** — собрать все оставшиеся строки в массив;
- **`&{ }`** — получить функцию-генератор, которая при каждом вызове отдаёт `next`;
- **`< >`** — это `next` (в скалярном контексте).

Объекты, которые отдаёт итератор, зависят от источника:

- для `iterator` адаптер создаёт сущность класса `$query->from` — **или** прокси-наследника, если в строке есть поля-алиасы, которых у сущности нет (см. `Aion::Aya::Adapter`);
- для `raw_iterator` отдаётся «сырая» строка — `HashRef` с именами колонок.

# FEATURES

## adapter

Обязательный адаптер. Требование ослабленное (`is => 'ro*'`), то есть итератор держит **слабую** ссылку на адаптер: адаптер должен жить отдельно, иначе он исчезнет и `next` упадёт.

## session

Сессия итератора. Даёт доступ к тому же состоянию запроса, по которому идут строки: `dbh`, `sth` и исходный `query`/`sql`. Итератор передаёт её в `adapter->next`, поэтому она же является единицей состояния и для протокола адаптера.

# METHODS

## next

Возвращает следующую строку через `$self->{adapter}->next($self->{session})` или `undef`, когда строки закончились.

Это тот метод, который вызывают все перегрузки; реализует его адаптер.

```perl
my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['one', 'two', 'three']});

my $first = $iterator->next;
$first              # -> 'one'
$iterator->next     # -> 'two'
$iterator->next     # -> 'three'
$iterator->next     # -> undef
```

# EXAMPLES

## next

```perl
my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [1, 2, 3]});

my @values;
while(my $value = $iterator->next) { push @values, $value }

"@values"       # -> "1 2 3"

$iterator->next # -> undef
$iterator->next # -> undef
```

## @{ }

```perl
my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['a', 'b', 'c']});

my $rows = \@$iterator;

ref $rows           # -> 'ARRAY'
scalar @$rows       # -> 3
"@$rows"            # -> "a b c"

scalar @{$iterator} # -> 0
```

## &{ }

```perl
my $adapter = Adapter::Mock->new;
my $generator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => [10, 20, 30]});

$generator->()   # -> 10
$generator->()   # -> 20
$generator->()   # -> 30
$generator->()   # -> undef

ref $generator   # -> 'Aion::Aya::Iterator'
```

## < >

```perl
my $adapter = Adapter::Mock->new;
my $iterator = Aion::Aya::Iterator->new(adapter => $adapter, session => {rows => ['x', 'y']});

my $first = <$iterator>;
$first           # -> 'x'
<$iterator>      # -> 'y'
<$iterator>      # -> undef
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Iterator module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
