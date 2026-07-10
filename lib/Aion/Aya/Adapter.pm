package Aion::Aya::Adapter;
# Осуществляет управление подключениями к базе, трансформирует

use common::sense;

use Aion -role;


# Трансформирует запрос в промежуточное представление
sub transform :Isa(Me => Query => (ArrayRef|HashRef|Str));



1;