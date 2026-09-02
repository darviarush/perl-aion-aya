package Aion::Aya::Adapter::MysqlAdapter;

use common::sense;

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';
with 'Aion::Aya::Adapter::Transform::SQL';

# Создаёт подключение
sub make_connect {
	my ($self) = @_;
	my $dbh = $self->next::make_connect;
	Coro::Mysql::unblock $dbh;
}

1;