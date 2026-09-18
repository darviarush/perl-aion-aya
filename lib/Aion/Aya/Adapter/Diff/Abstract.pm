package Aion::Aya::Adapter::Diff::Abstract;

use common::sense;

use Aion;

# Адаптер
has adapter => (is => 'ro', isa => 'Aion::Aya::Adapter');

# Сравнивает модели и структуру базы
sub diff :Isa(Me => ArrayRef[ClassName] => Any);

1;