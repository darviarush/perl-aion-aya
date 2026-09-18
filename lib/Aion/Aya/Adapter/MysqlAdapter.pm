package Aion::Aya::Adapter::MysqlAdapter;

use common::sense;

use Coro::Mysql;

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';
with 'Aion::Aya::Adapter::Transform::SQL';

# Класс для сравнения модели и базы
has diff_class => (is => 'ro', isa => PackageName, default => 'Aion::Aya::Adapter::Diff::DDL');

# Создаёт подключение
sub make_connect {
	my ($self) = @_;
	my $dbh = $self->next::make_connect;
	Coro::Mysql::unblock $dbh;
}

1;