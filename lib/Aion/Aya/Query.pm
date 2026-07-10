package Aion::Aya::Query;

use common::sense;

use aliased 'Aion::Aya::Query::Expr';
use aliased 'Aion::Aya::Query::Expr::Field';
use aliased 'Aion::Aya::Query::Join' => 'xJoin';
use aliased 'Aion::Aya::Query::Expr::Fn';
use aliased 'Aion::Aya::Query::Expr::Op';
use aliased 'Aion::Aya::Query::Order';

use constant {
	SELECT => 'select',
	INSERT => 'insert',
	UPDATE => 'update',
	DELETE => 'delete',
};

use Aion;

# Операция
has operation => (is => 'ro', isa => Enum[SELECT, INSERT, UPDATE, DELETE], default => SELECT);

# Поля для получения
has select => (is => 'ro', isa => HashRef[Expr], lazy => 0, default => sub {+{}});

# Объединения с другими таблицами
has join => (is => 'ro', isa => HashRef[Str], lazy => 0, default => sub {+[]});

# Условие для фильтрации
has filter => (is => 'ro', isa => Maybe[Expr]);

# Группировки
has group_by => (is => 'ro', isa => ArrayRef[Expr], lazy => 0, default => sub {+[]});

# Условие для фильтрации после группировки
has having => (is => 'ro', isa => Maybe[Expr]);

# Сортировки
has order_by => (is => 'ro', isa => ArrayRef[Object[Expr] | Object[Order]], lazy => 0, default => sub {+[]});

# Смещение
has offset => (is => 'ro', isa => Maybe[PositiveInt]);

# Ограничение
has limit => (is => 'ro', isa => Maybe[PositiveInt]);

# Клонирование
sub clone {
	my $self = shift;
	ref($self)->new(%$self, @_);
}

1;