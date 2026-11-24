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

undef *from;

# Операция
has operation => (is => 'ro+', isa => Enum[SELECT, INSERT, UPDATE, DELETE], default => SELECT);

# Поля в выборке: expr AS name
has select => (is => 'ro', isa => CycleTuple[Expr, Str], lazy => 0, default => sub {+[]});

# Из какого класса порождать сущности
has from => (is => 'ro+', isa => ClassName);

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

__END__

=encoding utf-8

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

undef *from;

=head1 Операция

has operation => (is => 'ro+', isa => Enum[SELECT, INSERT, UPDATE, DELETE], default => SELECT);

=head1 Поля в выборке: expr AS name

has select => (is => 'ro', isa => CycleTuple[Expr, Str], lazy => 0, default => sub {+[]});

=head1 Из какого класса порождать сущности

has from => (is => 'ro+', isa => ClassName);

=head1 Объединения с другими таблицами: type => field => alias

has join => (is => 'ro', isa => ArrayRef[xJoin], lazy => 0, default => sub {+[]});

=head1 Условие для фильтрации

has filter => (is => 'ro', isa => Maybe[Expr]);

=head1 Группировки

has group_by => (is => 'ro', isa => ArrayRef[Expr], lazy => 0, default => sub {+[]});

=head1 Условие для фильтрации после группировки

has having => (is => 'ro', isa => Maybe[Expr]);

=head1 Сортировки

has order_by => (is => 'ro', isa => CycleTuple[Object[Expr], Enum['ASC', 'DESC']], lazy => 0, default => sub {+[]});

=head1 Смещение

has offset => (is => 'ro', isa => Maybe[PositiveInt]);

=head1 Ограничение

has limit => (is => 'ro', isa => Maybe[Nat]);

=head1 Клонирование

sub clone {
    my $self = shift;
    ref($self)->new(%$self, @_);
}

1;

B<END>

=encoding utf-8

=head1 NAME

Aion::Aya::Query - запрос к базе (DQL): выборка, условия, соединения, сортировка и пагинация

=head1 SYNOPSIS

 package Storage::Book::Synopsis {
     use Aion;
 
     has title => (is => 'ro', isa => Str);
 }
 
 use Aion::Aya::Query;
 use aliased 'Aion::Aya::Query::Join' => 'xJoin';
 
 my $query = Aion::Aya::Query->new(
     from => 'Storage::Book::Synopsis',
     select => [],
     join => [xJoin->new(field => 'author', alias => 'a', join => 'left')],
     group_by => [],
     having => undef,
     order_by => [],
     offset => 20,
     limit => 10,
 );
 
 $query->operation                   # -> 'select'
 $query->from                        # -> 'Storage::Book::Synopsis'
 scalar(@{$query->select})           # -> 0
 $query->join->[0]->{alias}          # -> 'a'
 $query->join->[0]->{join}           # -> 'left'
 scalar(@{$query->group_by})         # -> 0
 $query->having                      # -> undef
 scalar(@{$query->order_by})         # -> 0
 $query->offset                      # -> 20
 $query->limit                       # -> 10
 $query->filter                      # -> undef
 
 # Обязателен только from; остальное по умолчанию пусто
 my $empty = Aion::Aya::Query->new(from => 'Storage::Book::Synopsis');
 
 scalar(@{$empty->select})   # -> 0
 scalar(@{$empty->join})     # -> 0
 scalar(@{$empty->order_by}) # -> 0
 $empty->limit               # -> undef
 
 Aion::Aya::Query->new # @-> from required

=head1 DESCRIPTION

C<Aion::Aya::Query> — объектное представление запроса. Модуль ничего не знает о базе: он только хранит части запроса. Запрос можно собрать, склонировать и дополнить, а затем передать адаптеру — тот отдаст C<Aion::Aya::Iterator> или число затронутых строк.

Операция по умолчанию — C<select>. Остальные операции (C<insert>, C<update>, C<delete>) используются C<Aion::Aya::Box> и C<Aion::Aya::Appearance> при записи.

Обязателен только C<from>; остальные части по умолчанию пусты.

=head1 SUBROUTINES

=head2 clone ()

Создаёт независимую копию запроса: изменения в копии не затрагивают оригинал.

 package Storage::Book::Clone {
     use Aion;
 
     has title => (is => 'ro', isa => Str);
 }
 
 use Aion::Aya::Query;
 
 my $query = Aion::Aya::Query->new(from => 'Storage::Book::Clone', limit => 10);
 
 my $copy = $query->clone(limit => 25);
 
 ref $copy      # -> 'Aion::Aya::Query'
 $copy->from    # -> 'Storage::Book::Clone'
 $query->limit  # -> 10
 $copy->limit   # -> 25
 
 my $copy2 = $copy->clone(limit => 30);
 $copy2->limit  # -> 30
 $copy->limit   # -> 25
 $query->limit  # -> 10

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
