package Aion::Aya::Adapter::Diff::MemDiff;

use common::sense;

use aliased 'Aion::Aya::Table';

use Aion;

extends 'Aion::Aya::Adapter::Diff::Abstract';

# Сравнивает два списка таблиц, возвращает инструкции DQL, которые нужно выполнить, чтобы привести к 1-й
sub diff :Isa(Me => HashRef[Table] => HashRef[Table] => ArrayRef[Str]) {
	my ($self, $models, $database) = @_;

	my @ddl;
	for my $table (sort keys %$models) {
		push @ddl, $self->show_create_table($models->{$table}) unless exists $database->{$table};
	}
	for my $table (sort keys %$database) {
		push @ddl, $self->show_drop_table($database->{$table}) unless exists $models->{$table};
	}

	# TODO: alter table add column, drop column, add index, etc
	
	\@ddl;
}

# Заполняет таблицу на основе модели
sub model2table :Isa(Me => Model => Table) {
	my ($self, $model) = @_;
	
	my $cls = $model->{pkg};
	
	my $feature_href = $Aion::META{$cls}{feature};

	my @columns;
	for my $field (sort { $a->{col}{order} <=> $b->{col}{order} } grep { $_->{col} } values %{$model->{field}}) {
		my $name = $field->{name};
		my $feature = $feature_href->{$name};
		my $isa = $feature->{isa};
		my $is_nullable = $isa->{name} eq 'Maybe'? do { $isa = $isa->{args}[0]; 1 }: 0;

		my $col = $field->{col};

		push @columns, {
			name => $col->{name},
			type => $col->{type} // $self->isa2type($isa),
			is_nullable => $col->{is_nullable} // $feature->{isa}{name} eq 'Maybe',
			default => $col->{default} // '',
			options => [], # В DBD::Mem нет опций
			comment => '', # В DBD::Mem нет комментариев
			order => $field->{order},
		};
	}

	my $pk = $model->primary_key;
	my @pk_columns = $pk? map { $model->col_name($_) } @{$pk->{fields}}: ();

	Table->new(
		table => $model->table,
		primary_key => {columns => \@pk_columns, options => $pk? $pk->{options} // []: []},
		columns => \@columns,
	);
}

# Информация о таблицах из DBD::Mem
sub structure :Isa(Me => HashRef[Table]) {
	my ($self) = @_;

	my %table;

	for my $table ($self->get_tables) {
		my @columns = $self->get_columns;
		$table{$table} = Table->new(
			table => $table,
			primary_key => {columns => ['id'], options => []},
			columns => \@columns,
		);
	}

	\%table
}

our %DATA_TYPE = (
	TinyInt => 'tinyint',
	LongInt => 'int',
	Int => 'int',
);

sub isa2type {
	my ($self, $isa) = @_;

	if($isa->is_intersection) {
		# TODO: в типах Aion ограничения длины указываются так: Str & Len[10], соответственно нужно получить из этого varchar(10)
		# Num => double
		# Double => double
		# Float => float
		# Int => int
		# PositiveInt => int unsigned
		# Str или Uni => varchar(255)
		# Bin => binary(255)
		# 
		my ($len) = grep { $_->{name} eq 'Len' } @{$isa->{args}};
		if($len) {}
	}
	
	$DATA_TYPE{$isa->{name}} // die "Not convert isa $isa to type!"
}

# Получает таблицы из базы
sub get_tables {
	my ($self) = @_;
	my @tables;
	my $dbh = $self->adapter->connect;
	my $sth_tables = $dbh->table_info(undef, undef, undef, 'TABLE');
	while (my $row = $sth_tables->fetchrow_hashref) {
		push @tables, $row->{TABLE_NAME};
	}
	$sth_tables->finish;
	$self->adapter->finish($dbh);
	@tables
}

# Получает столбцы таблицы из базы
sub get_columns {
	my ($self, $table) = @_;
	my @columns;
	my $order = 0;
	my $dbh = $self->adapter->connect;
	my $sth_columns = $dbh->column_info(undef, undef, $table, undef);
	while(my $col = $sth_columns->fetchrow_hashref) {
		my $is_nullable = defined $col->{IS_NULLABLE} && $col->{IS_NULLABLE} eq 'YES';
		push @columns, {
			name => $col->{COLUMN_NAME},
			type => $col->{TYPE_NAME},
			is_nullable => $is_nullable,
			default => $col->{COLUMN_DEF}, # Используем SQL::Statement, который поддерживаеи ANSI-SQL типизацию
			options => '', # DBD::Mem не поддерживает autoincrement и т.п.
			comment => '', # DBD::Mem не поддерживает комментарии
			order => $order++,
		};
	}
	$sth_columns->finish;
	$self->adapter->finish($dbh);
	@columns
}

# Возвращает индексы из SQL::Statement
sub get_indexes {
	my ($self, $table) = @_;

	my $dbh = $self->adapter->connect;

	my $sth_pk = $dbh->primary_key_info(undef, undef, $table);
	my @pk_columns; my %pk_columns;
	while(my $row = $sth_pk->fetchrow_hashref) {
		push @pk_columns, $row->{COLUMN_NAME};
		$pk_columns{$row->{COLUMN_NAME}} = 1;
	}
	
	# Запрашиваем информацию об индексах для таблицы
	# Передаем: $catalog, $schema, $table, $unique_only, $quick
	my $sth_indexes = $dbh->statistics_info(undef, undef, $table, 0, 0);
	
    while (my $index = $sth_indexes->fetchrow_hashref) {
        next if defined $index->{TYPE} && $index->{TYPE} == 0; # Пропускаем статистику таблицы
        next if $pk_columns{$index->{COLUMN_NAME}}; # Пропускаем, если это уже PK
        #$idx_fields{$i->{COLUMN_NAME}} = $i->{INDEX_NAME};
        # TODO: дописать
    }

	$sth_indexes->finish;
	$self->adapter->finish($dbh);

	# TODO: дописать return
}

# Имя поля или таблицы
sub word {
	my ($self, $word) = @_;
	$self->adapter->transformator->word($word);
}

#@category DDL базы

# стандартные опции базы
sub show_definition_database {
	my ($self, $base) = @_;
	return
		defined($base->charset)? ("DEFAULT CHARACTER SET", $self->word($base->charset)): (),
		defined($base->collation)? ("DEFAULT COLLATE", $self->word($base->collation)): ();
}

# создать базу
sub show_create_database {
	my ($self, $base) = @_;
	join " ", "CREATE DATABASE", $self->word($base->name), $self->show_definition_database($base);
}

# удалить базу
sub show_drop_database {
	my ($self, $base) = @_;
	join " ", "DROP DATABASE", $self->word($base->name)
}

# изменить базу
sub show_modify_database {
	my ($self, $base) = @_;
	join " ", "ALTER DATABASE", $self->word($base->name), $self->show_definition_database($base);
}

#@category DDL таблиц

# опции таблицы в DBD::Mem не поддерживаются
sub show_definition_table {
	my ($self, $tab, $create) = @_;
	'';
}

# внутренности таблицы
sub show_create_definition {
	my ($self, $tab) = @_;

	my @pk = @{$tab->primary_key->{columns} // []};

	join(",\n",
		(map { $self->show_column($_, 1) } @{$tab->columns}),
		(@pk? 'PRIMARY KEY (' . join(', ', map { $self->word($_) } @pk) . ')': ()),
		(map { $self->show_index($_) } @{$tab->unique_keys}, @{$tab->index_keys}),
		(map { $self->show_foreign($_) } @{$tab->foreign_keys}),
	);
}

# создать таблицу
sub show_create_table {
	my ($self, $tab) = @_;
	join '', "CREATE TABLE ", $self->word($tab->table), " (\n", $self->show_create_definition($tab), "\n)";
}

# модифицировать опции таблицы
sub show_modify_table {
	my ($self, $tab) = @_;
	join '', "ALTER TABLE ", $self->word($tab->table), " ", $self->show_definition_table($tab);
}

# переименовать таблицу
sub show_rename_table {
	my ($self, $tab, $to) = @_;
	join '', "ALTER TABLE ", $self->word($tab->table), " RENAME TO ", $self->word($to);
}

# удалить таблицу
sub show_drop_table {
	my ($self, $tab) = @_;
	join '', "DROP TABLE ", $self->word($tab->table);
}

# очистить таблицу
sub show_truncate_table {
	my ($self, $tab) = @_;
	join '', "DELETE FROM ", $self->word($tab->table);
}

#@category DDL столбцов

# определение столбца без названия (col — хеш Aion::Aya::Table->Column)
sub show_definition_column {
	my ($self, $col, $with_keys) = @_;

	join ' ', $col->{type} || 'TEXT',
		defined($col->{is_nullable}) && !$col->{is_nullable}? 'NOT NULL': (),
		defined($col->{default}) && $col->{default} ne ''? ('DEFAULT', $self->word($col->{default})): (),
		$col->{options}? $col->{options}: ();
}

# столбец с названием
sub show_column {
	my ($self, $col, $with_keys) = @_;
	join ' ', $self->word($col->{name}), $self->show_definition_column($col, $with_keys);
}

#@category DDL индексов

# формирует индекс без его названия (idx — хеш Aion::Aya::Table->Key)
sub show_definition_index {
	my ($self, $idx) = @_;
	join '', '(', join(', ', map { $self->word($_) } @{$idx->{columns}}), ')';
}

# индекс c типом и названием
sub show_index {
	my ($self, $idx) = @_;
	join '', 'KEY ', $self->word($idx->{name}), ' ', $self->show_definition_index($idx);
}

# формирует ссылку без названия (fk — хеш Aion::Aya::Table->ForeignKey)
sub show_definition_foreign {
	my ($self, $fk) = @_;
	join '', 'FOREIGN KEY (', join(', ', map { $self->word($_) } @{$fk->{columns}}), ') REFERENCES ',
		$self->word($fk->{to_table}), ' (', join(', ', map { $self->word($_) } @{$fk->{to_columns}}), ')';
}

# ссылка c названием
sub show_foreign {
	my ($self, $fk) = @_;
	join '', 'CONSTRAINT ', $self->word($fk->{name}), ' ', $self->show_definition_foreign($fk);
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Adapter::Diff::MemDiff - comparison of models with the DBD::Mem structure and DDL generation

=head1 SYNOPSIS

File lib/DiffExample.pm:

	package DiffExample;
	use common::sense;
	
	use Aion;
	use Aion::Aya::Table;
	use Aion::Aya::Adapter::Diff::MemDiff;
	use Aion::Aya::Adapter::Transform::SQL;
	
	# MemDiff берёт экранирование у transformator адаптера, поэтому нужен adapter
	package DiffAdapter {
		use Aion;
		with 'Aion::Aya::Adapter';
	
		has adapter => (is => 'ro', isa => 'Aion::Aya::Adapter', default => sub { undef });
		has transformator => (is => 'ro', isa => 'Aion::Aya::Adapter::Transform::Abstract', default => sub { Aion::Aya::Adapter::Transform::SQL->new });
		sub iterator :Isa(Me => Object['Aion::Aya::Query'] => Object['Aion::Aya::Iterator']) { }
		sub execute :Isa(Me => Object['Aion::Aya::Query'] => PositiveInt) { }
		sub next_val :Isa(Me => Object['Aion::Aya'] => Str) { }
		sub next :Isa(Me => Hashref => Any) { }
	}
	
	package DiffExample;
	our $diff = bless { adapter => DiffAdapter->new }, 'Aion::Aya::Adapter::Diff::MemDiff';
	
	our $book = Aion::Aya::Table->new(
		table => 'book',
		primary_key => {columns => ['id'], options => []},
		columns => [
			{name => 'id', type => 'int', is_nullable => 0, default => '', options => '', comment => '', order => 0},
			{name => 'title', type => 'varchar(255)', is_nullable => 0, default => '', options => '', comment => '', order => 1},
		],
	);
	
	1;



	use DiffExample;
	
	my $ddl = $DiffExample::diff->diff({book => $DiffExample::book}, {});
	
	ref $ddl  # -> 'ARRAY'
	scalar @$ddl # -> 1
	$ddl->[0] =~ /^CREATE TABLE book/ # -> 1

=head1 DESCRIPTION

C<MemDiff> is an implementation of C<Aion::Aya::Adapter::Diff::Abstract> for an in-memory database on C<DBD::Mem>. The module can do two things:

=over

=item * B<compare> a set of models with a set of base tables (C<diff>) and return DDL that brings the base to the models;

=item * B<build DDL text> based on the table description (C<Aion::Aya::Table>): C<CREATE TABLE>, C<DROP TABLE>, C<ALTER TABLE>, columns, keys, foreign keys.

=back

C<Aion::Aya::Adapter::Diff::MysqlDiff> inherits C<MemDiff> and only changes C<model2table> (adds comments from annotations).

DDL methods collect text and names are escaped via C<word>, which delegates to C<< adapter-E<gt>transformator-E<gt>word >>. That's why C<MemDiff> is kept next to C<adapter>.

=head1 FEATURES

=head2 adapter

The adapter from which the connection (C<connect>/C<finish>), transformer (C<word>) and metadata are taken. Inherited from C<Abstract>.

=head1 SUBROUTINES

=head2 diff ($models, $database)

Compares two hashes “table name => C<Aion::Aya::Table>”: the model and the current database structure. Returns a reference to a DDL array:

=over

=item * the table is in the models, but not in the database → C<CREATE TABLE>;

=item * the table is in the database, but not in the models → C<DROP TABLE>;

=item * identical tables → nothing.

=back

Changes within existing tables (ALTER) are not yet evaluated.

	use DiffExample;
	
	my $ddl = $DiffExample::diff->diff({book => $DiffExample::book}, {});
	
	scalar @$ddl # -> 1
	$ddl->[0] =~ /^CREATE TABLE book/ # -> 1
	
	# Одинаковые структуры — пустой список
	my $same = $DiffExample::diff->diff({book => $DiffExample::book}, {book => $DiffExample::book});
	
	scalar @$same # -> 0

=head2 model2table ($model)

Builds C<Aion::Aya::Table> from the model (C<Aion::Aya::Model>): iterates through C<col> fields by C<order>, takes types via C<isa2type>, takes into account C<Maybe> (nullable) and the primary key. C<MemDiff> has no comments or options because C<DBD::Mem> does not support them.

	use DiffExample;
	
	ref $DiffExample::diff->can('model2table') # -> 'CODE'

=head2 structure ()

Reads the table structure from C<DBD::Mem> (C<table_info>/C<column_info>) and returns the hash "name => C<Aion::Aya::Table>". Requires a working C<< adapter-E<gt>connect >>.

=head2 isa2type ($isa)

Converts an Aion type to a SQL type name. For C<DBD::Mem>, C<Int>, C<TinyInt>, C<LongInt> are supported (C<int>/C<tinyint>/C<int>); unknown type - exception C<Not convert isa ... to type!>.

	use DiffExample;
	use Aion::Aya::Types;
	
	$DiffExample::diff->isa2type(Int())     # -> 'int'
	$DiffExample::diff->isa2type(TinyInt()) # -> 'tinyint'
	$DiffExample::diff->isa2type(LongInt()) # -> 'int'

=head2 get_tables ()

Returns the names of database tables via C<table_info>. Used in C<structure>.

=head2 get_columns ($table)

Returns a description of the table columns via C<column_info>: C<name>, C<type>, C<is_nullable>, C<default> (from C<SQL::Statement>), C<order>. C<options>/C<comment> are always empty.

=head2 get_indexes ($table)

Preparation: reads the primary key via C<primary_key_info> and statistics via C<statistics_info>, but does not return indexes yet.

=head2 word ($word)

Table/column name escaping: delegates to C<< adapter-E<gt>transformator-E<gt>word >>.

=head2 show_create_table ($table)

C<CREATE TABLE {table} (\n{columns, primary key, indexes, foreign keys}\n)>.

	use DiffExample;
	
	my $sql = $DiffExample::diff->show_create_table($DiffExample::book);
	
	$sql =~ /^CREATE TABLE book \(/ # -> 1
	$sql =~ /PRIMARY KEY \(id\)/     # -> 1

=head2 show_drop_table ($table)

C<DROP TABLE {table}>.

	use DiffExample;
	
	$DiffExample::diff->show_drop_table($DiffExample::book) # -> 'DROP TABLE book'

=head2 show_rename_table ($table, $to)

C<ALTER TABLE {table} RENAME TO {new name}>.

	use DiffExample;
	
	$DiffExample::diff->show_rename_table($DiffExample::book, 'book2') # -> 'ALTER TABLE book RENAME TO book2'

=head2 show_truncate_table ($table)

Clears a table: C<DELETE FROM {table}>.

	use DiffExample;
	
	$DiffExample::diff->show_truncate_table($DiffExample::book) # -> 'DELETE FROM book'

=head2 show_modify_table ($table)

C<ALTER TABLE {таблица}> + опции таблицы. There are no options in C<DBD::Mem> (C<show_definition_table> returns an empty string), so C<ALTER TABLE book> is obtained.

	use DiffExample;
	
	$DiffExample::diff->show_modify_table($DiffExample::book) # -> 'ALTER TABLE book '

=head2 show_create_definition ($table)

Internals of C<CREATE TABLE>: columns, C<PRIMARY KEY>, indexes (C<unique_keys>, C<index_keys>), foreign keys connected via C<,\n>.

	use DiffExample;
	
	my $t = Aion::Aya::Table->new(
		table => 'book',
		primary_key => {columns => ['id'], options => []},
		columns => [{name => 'id', type => 'int', is_nullable => 0, default => '', options => '', comment => '', order => 0}],
		index_keys => [{name => 'idx_book', columns => ['title'], options => []}],
	);
	
	$DiffExample::diff->show_create_definition($t) =~ /PRIMARY KEY \(id\),\nKEY idx_book \(title\)/ # -> 1

=head2 show_definition_table ($table, $create)

Table options. C<MemDiff> is always an empty string; heirs can override.

=head2 show_column ($col)

Column named: C<{name} {type [NOT NULL] [DEFAULT ...] [options]}>.

	use DiffExample;
	
	$DiffExample::diff->show_column({name => 'id', type => 'int', is_nullable => 0}) # -> 'id int NOT NULL'

=head2 show_definition_column ($col, $with_keys)

Unnamed column definition: type (default C<TEXT>), C<NOT NULL>, C<DEFAULT>, options.

	use DiffExample;
	
	$DiffExample::diff->show_definition_column({type => 'int', is_nullable => 0, default => 7}) # -> 'int NOT NULL DEFAULT 7'

=head2 show_index ($index)

An index named: C<KEY {name} ({columns})>.

	use DiffExample;
	
	$DiffExample::diff->show_index({name => 'idx_book', columns => ['title']}) # -> 'KEY idx_book (title)'

=head2 show_definition_index ($index)

Unnamed index: C<({columns})>.

=head2 show_foreign ($fk)

A foreign key named: C<CONSTRAINT {name} FOREIGN KEY ({columns}) REFERENCES {table} ({columns})>.

	use DiffExample;
	
	$DiffExample::diff->show_foreign({name => 'fk_book_author', to_table => 'author', columns => ['author_id'], to_columns => ['id']}) # -> 'CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES author (id)'

=head2 show_definition_foreign ($fk)

Unnamed foreign key: C<FOREIGN KEY (...) REFERENCES ... (...)>.

=head2 show_create_database / show_drop_database / show_modify_database / show_definition_database

DDL for the database (C<CREATE DATABASE>, C<DROP DATABASE>, C<ALTER DATABASE>). C<show_definition_database> returns C<DEFAULT CHARACTER SET>/C<DEFAULT COLLATE> pairs if the object has C<charset>/C<collation>.

=head1 GOTCHAS

=over

=item * B<< C<< MemDiff-E<gt>new >> crashes. >> C<model2table> in C<MemDiff> is declared as C<< :Isa(Me =E<gt> Model =E<gt> Table) >>, and the C<Abstract> contract is declared as C<< :Isa(Me =E<gt> Model =E<gt> Table) >> with type C<Aion::Aya::Model>; signatures do not match (C<Signature mismatch>). Plus the C<Model> in the signature resolves to the non-existent C<Object['Model']>. Therefore, in the examples, the object is created using C<bless>, but C<model2table> does not work yet.

=item * B<< C<adapter> is required for C<word>. >> DDL methods are called C<word> → C<< adapter-E<gt>transformator-E<gt>word >>, so C<adapter> is needed even for pure text generation.

=item * B<< C<diff> only works for C<Aion::Aya::Table>. >> Both arguments are checked as C<HashRef[Object['Aion::Aya::Table']]>, so you cannot pass column hashes instead of objects.

=item * B<ALTER of existing tables is not implemented.> C<diff> only does C<CREATE>/C<DROP>; column/index changes - C<TODO>.

=item * B<< C<structure> requires a working connection. >> It goes to C<< adapter-E<gt>connect >> and C<DBD::Mem>, so it is not checked in isolation from the database.

=back

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Adapter::Diff::MemDiff module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
