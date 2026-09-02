!ru:en
# NAME

Aion::Aya::Transaction - транзакция для Aion::Aya

# VERSION

0.0.0

# SYNOPSIS

Файл etc/include.yml:
```yaml
aion:
  eon:
    Aion::Aya::Adapter:
      class: Aion::Aya::Adapter::MemAdapter
    CHI:
      class: CHI
      arguments:
        driver: None
```

```perl
use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';
use aliased 'Liberia::Storage::Author::AuthorBox';

my $appearance = Appearance->new;

{
    my $tx = $appearance->transaction;

    my $author = Author->new(name => 'A.Rudazov');
    $appearance->persist($author)->flush;
    
    $tx->commit;
}

AuthorBox->find_one_by_name('A.Rudazov')->id # -> 1

{
    my $tx = $appearance->transaction;

    my $author = Author->new(name => 'Zero');
    $appearance->persist($author)->flush;
    
    $tx->rollback;
}

AuthorBox->find_one_by_name('Zero') # -> undef
```

# DESCRIPTION

`Aion::Aya::Transaction` — это транзакция базы данных, привязанная к текущему волокну (`Coro`). В одном волокне одновременно может быть только одна активная транзакция.

Транзакция объявляется у менеджера сущностей (`Aion::Aya::Appearance`). Пока она жива, все обращения к базе в текущем волокне (fiber) входят в неё. Её нужно завершить вызовом `commit` или `rollback`. Если переменная с транзакцией уйдёт из области видимости без `commit`, автоматически сработает `rollback`.

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

Дальше показаны две типовые сценария: **успешное сохранение** (с `commit`) и **откат** (с `rollback`).

Пусть есть сущность автора с первичным ключом и автоинкрементом:

Файл lib/Liberia/Storage/Author/Author.pm:
```perl
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
```

И его репозиторий:

Файл lib/Liberia/Storage/Author/AuthorBox.pm:
```perl
package Liberia::Storage::Author::AuthorBox;
use common::sense;
use Aion::Aya::Box;

for_box 'Liberia::Storage::Author::Author';

# Получить автора по имени
sub find_one_by_name {
	my ($self, $name) = @_;

	$self->query_builder->filter(name => $name)->first;
}

1;
```

# METHODS

## commit

Завершает транзакцию, фиксируя её (`commit` всех открытых соединений) и извлекая её из состояния адаптера.

```perl
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

my $appearance = Appearance->new;
my $tx = $appearance->transaction;

my $author = Author->new(name => 'Tolstoy L.N.');
$appearance->persist($author)->flush;

$tx->commit;

AuthorBox->find_one_by_name('Tolstoy L.N.')->id # -> 3
```

## rollback

Завершает транзакцию, откатывая её (`rollback` всех открытых соединений).

```perl
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

my $appearance = Appearance->new;
my $tx = $appearance->transaction;

my $author = Author->new(name => 'Dostoevsky F.M.');
$appearance->persist($author)->flush;

$tx->rollback;

AuthorBox->find_one_by_name('Dostoevsky F.M.') # -> undef
```

Если переменную, хранящую транзакцию, не закоммитить, то при уничтожении она вызовет `rollback`:

```perl
use common::sense;

use aliased 'Aion::Aya::Appearance';
use aliased 'Liberia::Storage::Author::Author';

sub create_attempt {
	my ($appearance, $name) = @_;

	my $tx = $appearance->transaction;
	my $author = Author->new(name => $name);
	$appearance->persist($author)->flush;
}

my $appearance = Appearance->new;
create_attempt($appearance, 'Chekhov A.P.');

AuthorBox->find_one_by_name('Chekhov A.P.') # -> undef
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
