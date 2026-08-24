package Aion::Aya::Query;

use common::sense;

use aliased 'Aion::Aya::Query::Expr';
use aliased 'Aion::Aya::Query::Expr::Field';
use aliased 'Aion::Aya::Query::Join' => 'xJoin';
use aliased 'Aion::Aya::Query::Expr::Fn';
use aliased 'Aion::Aya::Query::Expr::Op';

use constant {
	SELECT => 'select',
	INSERT => 'insert',
	UPDATE => 'update',
	DELETE => 'delete',
};

use Aion;

# Операция
has operation => (is => 'ro', isa => Enum[SELECT, INSERT, UPDATE, DELETE], default => SELECT);

# Поля в выборке: expr AS name
has select => (is => 'ro', isa => CycleTuple[Str, Expr], lazy => 0, default => sub {+{}});

# Объединения с другими таблицами: type => field => alias
has join => (is => 'ro', isa => ArrayRef[xJoin], lazy => 0, default => sub {+[]});

# Условие для фильтрации
has filter => (is => 'ro', isa => Maybe[Expr]);

# Группировки
has group_by => (is => 'ro', isa => ArrayRef[Expr], lazy => 0, default => sub {+[]});

# Условие для фильтрации после группировки
has having => (is => 'ro', isa => Maybe[Expr]);

# Сортировки
has order_by => (is => 'ro', isa => CycleTuple[Object[Expr], Enum['ASC', 'DESC']], lazy => 0, default => sub {+[]});

# Смещение
has offset => (is => 'ro', isa => Maybe[PositiveInt]);

# Ограничение
has limit => (is => 'ro', isa => Maybe[Nat]);

# Клонирование
sub clone {
	my $self = shift;
	ref($self)->new(%$self, @_);
}

1;