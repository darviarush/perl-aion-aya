package Aion::Aya::Adapter::MysqlAdapter;

use common::sense;

use Coro::Mysql;

use aliased 'Aion::Aya::Adapter::Transform::Abstract' => 'Transform';
use aliased 'Aion::Aya::Adapter::Transform::Mysql' => 'TransformMySQL';

use Aion;

with 'Aion::Aya::Adapter::Iterator::DBI';

# Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic)
has transformator => (is => 'ro', isa => Transform, default => sub { TransformMySQL->new });

# Создаёт подключение
sub make_connect {
	my ($self) = @_;
	my $dbh = $self->next::make_connect;
	Coro::Mysql::unblock $dbh;
}

1;