package Aion::Aya::Adapter::Iterator::DBI;

use common::sense;

use Coro qw//;
use Scalar::Util qw//;
use List::Util qw/first/;
use DBI qw//;

use aliased 'Aion::Aya::Iterator';
use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Transaction';

use Aion::Types qw/Nat/;

use Aion::Env::Etc MAX_FREE_CONNECTS => (isa => Nat, default => 10, key => 'aion.aya.max_free_connects');

use Aion -role;

with 'Aion::Aya::Adapter';

has dsn => (is => 'ro', isa => Str, default => sub { shift->default_dsn });
has login => (is => 'ro', isa => Maybe[Str]);
has password => (is => 'ro', isa => Maybe[Str]);
has attr => (is => 'ro', isa => HashRef);

# Свободные коннекты
has free_connects => (is => 'ro', isa => ArrayRef['DBI::db'], lazy => 0, default => sub {+[]});

# Максимум свободных коннектов
has max_free_connects => (is => 'ro', isa => Nat, default => MAX_FREE_CONNECTS);

# В транзакции по адресу coro
has in_transaction => (is => 'ro', isa => HashRef[Transaction]);

# DSN по умолчанию для диалекта; переопределяется драйвером (MemAdapter -> DBI:Mem:)
sub default_dsn { '' }

# Адрес текущего Coro
sub coro_current { pack 'J', Scalar::Util::refaddr $Coro::current }

# Устанавливает транзакцию
sub begin_transaction {
	my ($self, $transaction) = @_;
	die 'Transaction beginned!' if $self->{in_transaction}{$transaction->coro_current_addr};
	$self->{in_transaction}{$transaction->coro_current_addr} = $transaction;
	$self
}

# Комитит транзакцию
sub commit {
	my ($self, $transaction) = @_;
	my $old_transaction = delete $self->{in_transaction}{$transaction->coro_current_addr};
	die 'Other transaction beginned. Commit failed!' if $old_transaction != $transaction;
	for my $dbh (@{$transaction->{connects}}) {
		$dbh->commit;
		$self->finish($dbh);
	}
	$self
}

# Откатывает транзакцию
sub rollback {
	my ($self, $transaction) = @_;
	my $old_transaction = delete $self->{in_transaction}{$transaction->coro_current_addr};
	die 'Other transaction beginned. Rollback failed!' if $old_transaction != $transaction;
	for my $dbh (@{$transaction->{connects}}) {
		$dbh->rollback;
		$self->finish($dbh);
	}
	$self
}

# Коннект
sub connect {
	my ($self) = @_;

	my $free_connects = $self->{free_connects};
	while(my $dbh = shift @$free_connects) {
		return $dbh if $self->ping($dbh);
		$dbh->disconnect;
	}

	my $dbh = $self->make_connect;

	if(my $transaction = $self->{in_transaction}{&coro_current}) {
		$transaction->add_connect($dbh);
	}

	$dbh
}

# Вернуть коннект
sub finish {
	my ($self, $dbh) = @_;
	my $transaction = $self->{in_transaction}{&coro_current};
	return $self if $transaction && first { $_ == $dbh } @{$transaction->{connects}};

	my $free_connects = $self->{free_connects};
	$dbh->disconnect, return $self if @$free_connects >= $self->{max_free_connects};
	push @$free_connects, $dbh;

	$self
}

# Порождает итератор для сырого запроса
sub raw_iterator :Isa(Me => Str => Object[Iterator]) {
	my ($self, $sql) = @_;
	Iterator->new(adapter => $self, session => { sql => $sql });
}

# Порождает итератор
sub iterator :Isa(Me => Object['Aion::Aya::Query'] => Object[Iterator]) {
	my ($self, $query) = @_;
	Iterator->new(adapter => $self, session => { query => $query });
}

# Следующая строка из сессии
sub next :Isa(Me => HashRef => Any) {
	my ($self, $session) = @_;

	$session->{dbh} //= $self->connect;
	$session->{sth} //= do {
		my $query = $session->{sql} // $self->transformator->transform($session->{query});
		$self->prepare($session->{dbh}, $query);
	};

	my $row = $self->fetchrow($session->{sth});
	if(defined $row) {
		if($session->{sql}) { $row }
		else {
			my $class = $self->_entity_class($session->{query}, $row);
			$class->new(%$row);
		}
	} else {
		$session->{sth}->finish;
		delete $session->{sth};
		$self->finish($session->{dbh});
		delete $session->{dbh};
		$row
	}
}

# Для выполнения insert/update/delete
sub execute :Isa(Me => Object['Aion::Aya::Query'] => PositiveInt) {
	my ($self, $query) = @_;
	
	my $sql = $self->transformator->transform($query);
	my $dbh = $self->connect;
	my $rows_affected = $self->do($dbh, $sql);
	$self->finish($dbh);
	int $rows_affected;
}

# Выполнить операцию. Для расширения при наследовании
sub do {
	my ($self, $dbh, $sql) = @_;
	$dbh->do($sql);
}

# Получить следующую строку в виде хеша. Для расширения при наследовании
sub fetchrow {
	my ($self, $sth) = @_;
	$sth->fetchrow_hashref;
}

# Создание sth. Для расширения при наследовании
sub prepare {
	my ($self, $dbh, $sql) = @_;
	my $sth = $dbh->prepare($sql);
	$sth->execute;
	$sth
}

# Создание нового dbh. Для расширения при наследовании
sub make_connect {
	my ($self) = @_;
	
	DBI->connect(
		$self->{dsn},
		$self->{login},
		$self->{password},
		+{
			%{$self->{attr}},
			RaiseError => 1,
			PrintError => 0,
		}
	);
}

# Пинг. Для расширения при наследовании
sub ping {
	my ($self, $dbh) = @_;
	$dbh->ping or return '';
	$dbh->{AutoCommit} = 1;
}

1;