!ru:en
# NAME

Aion::Aya::Types - типы для колонок базы (целые по ширине, деньги, строки, блобы, сущности)

# SYNOPSIS

```perl
use Aion::Aya::Types;

1 ~~ TinyNat          # -> 1
-1 ~~ TinyNat         # -> ''
256 ~~ TinyNat        # -> ''

'Привет' ~~ TinyText  # -> 1
1 ~~ PositiveTinyInt  # -> 1
```

# DESCRIPTION

`Aion::Aya::Types` — набор подтипов для описания колонок таблиц в духе типов MySQL. Модуль делает две вещи:

1. **Переэкспортирует типы.** `@EXPORT` собирается из функций `Aion::Aya::Types` (заодно подтягиваются и базовые типы `Aion::Types`), поэтому после `use Aion::Aya::Types` все они доступны в вызывающем пакете по короткому имени: `TinyNat`, `Money`, `TinyText` и т. д.
2. **Объявляет свои подтипы** через `subtype` из `Aion::Types`.

Базой для «целых» служат `Bytes[n]` и `PositiveBytes[n]`: это диапазоны в `n` байт. `PositiveBytes[n]` покрывает `0..2^(8n)-1`, `Bytes[n]` — знаковый `-2^(8n-1)..2^(8n-1)-1`.

Проверка — это стандартная `~~`: `VALUE ~~ Тип` даёт `1`, если значение подходит, и `''`, если нет. Тип-функцию передают без скобок; параметризованные — `Char[4]`, `Decimal[10,2]`.

# TYPES

## PositiveTinyInt

Беззнаковое целое в 1 байт: `0..255`.

```perl
255 ~~ PositiveTinyInt # -> 1
256 ~~ PositiveTinyInt # -> ''
```

## PositiveShortInt

Беззнаковое целое в 2 байта: `0..65535`.

```perl
65535 ~~ PositiveShortInt # -> 1
0 ~~ PositiveShortInt     # -> 1
```

## PositiveMediumInt

Беззнаковое целое в 3 байта: `0..16777215`.

```perl
16777215 ~~ PositiveMediumInt # -> 1
```

## PositiveLongInt

Беззнаковое целое в 4 байта: `0..4294967295`.

```perl
4294967295 ~~ PositiveLongInt # -> 1
```

## PositiveBigInt

Беззнаковое целое в 8 байт: `0..2^64-1`.

```perl
1 ~~ PositiveBigInt # -> 1
-1 ~~ PositiveBigInt # -> ''
```

## TinyInt

Знаковое целое в 1 байт: `-128..127`.

```perl
-128 ~~ TinyInt # -> 1
127 ~~ TinyInt  # -> 1
128 ~~ TinyInt  # -> ''
```

## ShortInt

Знаковое целое в 2 байта: `-32768..32767`.

```perl
32767 ~~ ShortInt # -> 1
32768 ~~ ShortInt # -> ''
```

## MediumInt

Знаковое целое в 3 байта: `-8388608..8388607`.

```perl
8388607 ~~ MediumInt # -> 1
```

## LongInt

Знаковое целое в 4 байта: `-2147483648..2147483647`.

```perl
2147483647 ~~ LongInt # -> 1
```

## BigInt

Знаковое целое в 8 байт.

```perl
5 ~~ BigInt # -> 1
```

## TinyNat

Неотрицательное целое в 1 байт: `Nat & PositiveBytes[1]`, то есть `0..255`.

```perl
1 ~~ TinyNat  # -> 1
-1 ~~ TinyNat # -> ''
```

## ShortNat

`Nat & PositiveBytes[2]`: `0..65535`.

```perl
65535 ~~ ShortNat # -> 1
```

## MediumNat

`Nat & PositiveBytes[3]`: `0..16777215`.

```perl
16777215 ~~ MediumNat # -> 1
```

## LongNat

`Nat & PositiveBytes[4]`: `0..4294967295`.

```perl
4294967295 ~~ LongNat # -> 1
```

## BigNat

`Nat & PositiveBytes[8]`.

```perl
1 ~~ BigNat # -> 1
```

## Money

Денежное значение: `Range[-92233720368547758.08, +92233720368547758.07]`.

```perl
100 ~~ Money   # -> 1
12.5 ~~ Money  # -> 1
```

## Decimal[A, B]

Число с не более чем `A - B` цифрами до точки и дробной частью.

```perl
12.34 ~~ Decimal[10,2]    # -> 1
-12.34 ~~ Decimal[10,2]   # -> 1
12345678.9 ~~ Decimal[10,2] # -> 1
123456789.1 ~~ Decimal[10,2] # -> ''
```

## Binary[A]

Двоичная строка длины не более `A` байт.

```perl
'abcd' ~~ Binary[4]  # -> 1
'abcde' ~~ Binary[4] # -> ''
```

## Varbinary[A]

Двоичная строка переменной длины не более `A` байт: `Bin & Len[A]`.

```perl
'ab' ~~ Varbinary[2]   # -> 1
'abc' ~~ Varbinary[2]  # -> ''
```

## Char[A]

Unicode-строка длины не более `A` символов: `Uni & Len[A]`.

```perl
'abc' ~~ Char[3]  # -> 1
'я' ~~ Char[1]  # -> 1
'яя' ~~ Char[1] # -> ''
```

## Varchar[A]

Unicode-строка переменной длины не более `A` символов: `Uni & Len[A]`.

```perl
'abc' ~~ Varchar[5] # -> 1
'аб' ~~ Varchar[2]  # -> 1
'абв' ~~ Varchar[2] # -> ''
```

## TinyText

Unicode-строка до 255 символов: `Uni & Len[255]`.

```perl
'abc' ~~ TinyText    # -> 1
'Привет' ~~ TinyText # -> 1
```

## ShortText

Unicode-строка до 65535 символов: `Uni & Len[65_535]`.

```perl
'abc' ~~ ShortText    # -> 1
'Привет' ~~ ShortText # -> 1
```

## MediumText

Unicode-строка до 16777215 символов: `Uni & Len[16_777_215]`.

```perl
'abc' ~~ MediumText    # -> 1
'Привет' ~~ MediumText # -> 1
```

## LongText

Unicode-строка до 4294967295 символов: `Uni & Len[4_294_967_295]`.

```perl
'abc' ~~ LongText    # -> 1
'Привет' ~~ LongText # -> 1
```

## TinyBlob

Бинарные данные до 255 байт: `Bin & Len[255]`.

```perl
'bytes' ~~ TinyBlob # -> 1
```

## ShortBlob

Бинарные данные до 65535 байт: `Bin & Len[65_535]`.

```perl
'bytes' ~~ ShortBlob # -> 1
```

## MediumBlob

Бинарные данные до 16777215 байт: `Bin & Len[16_777_215]`.

```perl
'bytes' ~~ MediumBlob # -> 1
```

## LongBlob

Бинарные данные до 4294967295 байт: `Bin & Len[4_294_967_295]`.

```perl
'bytes' ~~ LongBlob # -> 1
```

## Entity[class, appearance_key?]

Тип-сущность: `Object[class]`, который умеет приводиться из строки-идентификатора через `coerce`. Для `Str` он берёт `Appearance` (по умолчанию `Aion::Aya::Appearance`), находит первичный ключ модели и ищет объект по нему; если не нашёл — оставляет строку как есть.

Используется в `has … isa => Entity[...]`, чтобы можно было передать id вместо объекта. Пример здесь не приводится: конструктору нужен рабочий `Aion::Aya::Appearance` с базой, а библиотека ещё не дописана.

# GOTCHAS

* **`Entity` требует рабочего `Appearance`.** Приведение `Str → объект` идёт через `Aion->pleroma->resolve('Aion::Aya::Appearance')` и `QueryBuilder`, поэтому в отрыве от базы/`Appearance` тип не работает.

# NOMENCLATURE

В объявлении `subtype "Имя[A, b]", …` имена параметров имеют значение:

* **Одна заглавная буква** (`A`, `B`, …) — параметр является объектом `Aion::Type` (самим типом), а не значением. С ним работают как с типом: `A->test`, `A->include($val)`.
* **Строчные имена** (`n`, `from`, `to`, `a`, `b`) — обычные значения, с ними можно делать арифметику и подставлять их в строки/regexp.

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Types module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
