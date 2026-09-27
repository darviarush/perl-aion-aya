package Aion::Aya::Adapter::MysqlAdapter;

use common::sense;

use Coro::Mysql;

use aliased 'Aion::Aya::Adapter::Transform::SQL';

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';

# Класс для сравнения модели и базы
has diff_class => (is => 'ro', isa => PackageName, default => 'Aion::Aya::Adapter::Diff::DDL');

# Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic)
has transformator => (is => 'ro', isa => SQL, default => sub { SQL->new });

# Создаёт подключение
sub make_connect {
	my ($self) = @_;
	my $dbh = $self->next::make_connect;
	Coro::Mysql::unblock $dbh;
}

1;