package Aion::Aya::Adapter::Diff::Abstract;

use common::sense;

use aliased 'Aion::Aya::Model';
use aliased 'Aion::Aya::Table';

use Aion;

# Адаптер
has adapter => (is => 'ro+', isa => 'Aion::Aya::Adapter');

# Сравнивает два списка таблиц, возвращает инструкции DQL, которые нужно выполнить, чтобы привести к 1-й
sub diff :Isa(Me => HashRef[Table] => HashRef[Table] => ArrayRef[Str]);

# Информация о таблицах
sub structure :Isa(Me => HashRef[Table]);

# Заполняет таблицу на основе модели
sub model2table :Isa(Me => Model => Table);

# Преобразует тип Aion в тип базы
sub isa2type :Isa(Me => Object['Aion::Type'] => Any);

1;