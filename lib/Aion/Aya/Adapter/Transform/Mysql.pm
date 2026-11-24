package Aion::Aya::Adapter::Transform::Mysql;
# DML-диалект MySQL

use common::sense;

use Aion;

extends 'Aion::Aya::Adapter::Transform::SQL';

# MySQL экранирует идентификаторы обратными кавычками
sub quoteword {
	my ($self, $word) = @_;
	"`$word`"
}

1;
