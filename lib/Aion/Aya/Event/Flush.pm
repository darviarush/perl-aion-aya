package Aion::Aya::Event::Flush;
# Базовое событие flush (относится ко всему flush, а не к одной сущности)

use common::sense;

use Aion;

extends 'Aion::Aya::Event';

# Окружение / менеджер сущностей, в котором происходит flush
has adapter => (is => 'ro', isa => Object);

1;
