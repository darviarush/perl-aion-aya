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

sub isa_name2type {
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
