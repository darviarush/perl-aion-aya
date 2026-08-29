package Aion::Aya::Event::Entity;
# Базовое событие конкретной сущности

use common::sense;

use Aion;

extends 'Aion::Aya::Event';

# Окружение / менеджер сущностей, в котором произошло событие
has adapter => (is => 'ro', isa => Object);

# Сущность, с которой связано событие
has entity => (is => 'ro', isa => Object);

1;
