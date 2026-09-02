# NAME

Aion::Aya::Transaction - транзакция для Aion::Aya

# VERSION

0.0.0

# SYNOPSIS

Транзакция объявляется у менеджера сущностей (`Aion::Aya::Appearance`). Пока она жива, все обращения к базе в текущем волокне (fiber) входят в неё. Её нужно завершить вызовом `commit` или `rollback`. Если переменная с транзакцией уйдёт из области видимости без `commit`, автоматически сработает `rollback`:

```perl
use common::sense;

use Aion::Aya;

my $appearance = Aion::Aya::Appearance->new;

{
    my $tx = $appearance->transaction;      # открываем транзакцию

    # ... создаём и сохраняем объекты ...

    $tx->commit;                            # фиксируем изменения
}

{
    my $tx = $appearance->transaction;
    # ... сохраняем объекты ...
    $tx->rollback;                          # откатываем всё, что сделали
}
```

# DESCRIPTION

`Aion::Aya::Transaction` — это транзакция базы данных, привязанная к текущему волокну (`Coro`). В одном волокне одновременно может быть только одна активная транзакция.

Транзакция связана со своим адаптером: при создании она вызывает у адаптера `begin_transaction($self)`, и адаптер запоминает её под адресом текущего волокна. Все соединения (`DBH`), которые будут открыты в этом волокне во время жизни транзакции, добавляются в неё — так что `commit`/`rollback` распространяется на всю работу внутри транзакции.

# STEP BY STEP

Открыть транзакцию:

	my $tx = $appearance->transaction;

Выполнить нужную работу — например, сохранить несколько объектов (всё это происходит именно в пределах транзакции):

	$appearance->persist($book)->flush;

Зафиксировать изменения, если всё прошло успешно:

	$tx->commit;

Либо отменить изменения:

	$tx->rollback;

# INIT

По умолчанию у `Aion::Aya::Appearance` подключён адаптер через контейнер эонов (`Aion::Pleroma`), например in‑memory драйвер. Транзакция использует именно адаптер менеджера сущностей, из которого была получена.

# METHODS

## commit

	$tx->commit;

Завершает транзакцию, фиксируя её (`commit` всех открытых соединений) и извлекая её из состояния адаптера.

## rollback

	$tx->rollback;

Завершает транзакцию, откатывая её (`rollback` всех открытых соединений).

# EXAMPLES

Дальше показаны две типовые сценария: **успешное сохранение** (с `commit`) и **откат** (с `rollback`).

Пусть есть сущность автора с первичным ключом и автоинкрементом:

	package Liberia::Storage::Author::Author;
	use common::sense;
	use Aion::Aya;

	# Authors of the Liberia
	presents 'authors';

	# The identifier
	has id => (is => 'ro', isa => Nat, pk => 1, next => -identity);

	# Name of the author
	has name => (is => 'ro', isa => NonEmptyStr, col => 1, unique => 1);

	1;

## Фиксация — `commit`

```perl
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

my $appearance = Appearance->new;
my $tx = $appearance->transaction;                 # открыли транзакцию

# Внутри транзакции создаём и сохраняем автора
my $author = Author->new(name => 'Tolstoy L.N.');
$appearance->persist($author)->flush;

$tx->commit;                                       # фиксируем
# author теперь сохранён в базе
```

## Откат — `rollback`

```perl
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

my $appearance = Appearance->new;
my $tx = $appearance->transaction;                 # открыли транзакцию

my $author = Author->new(name => 'Dostoevsky F.M.');
$appearance->persist($author)->flush;

$tx->rollback;                                     # откатываем
# author НЕ сохранён — изменений в базе нет
```

## Автоматический откат при выходе из области видимости

Если переменную, хранящую транзакцию, не закоммитить, то при уничтожении она будет откачена:

```perl
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

sub create_attempt {
	my ($appearance, $name) = @_;

	my $tx = $appearance->transaction;
	my $author = Author->new(name => $name);
	$appearance->persist($author)->flush;
	# намеренно не вызываем commit/rollback — сработает rollback
}

my $appearance = Appearance->new;
create_attempt($appearance, 'Chekhov A.P.');
# автор не сохранён, потому что транзакция была откачена при выходе из create_attempt
```

# GOTCHAS

* Транзакция привязана к текущему волокну; не переносите её в другое волокно.
* В одном волокне единовременно открыта только одна транзакция — вторая попытка `begin_transaction` для того же волокна вызовет исключение.
* Завершать транзакцию стоит явно (`commit`/`rollback`); полагаться на автоматический откат при выходе из области видимости допустимо, но лучше не затягивать транзакцию.

# SUBROUTINES

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
