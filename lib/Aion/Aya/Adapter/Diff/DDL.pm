package Aion::Aya::Adapter::Diff::DDL;
# DDL - отдельный класс, а не роль.
# Он получает adapter в качестве сессии для запросов.
# Имеет

use common::sense;

use aliased 'Aion::Aya::Table';

use Aion;

extends 'Aion::Aya::Adapter::Diff::Abstract';

# Сравнивает два списка таблиц, возвращает инструкции DQL, которые нужно выполнить, чтобы привести к 1-й
sub diff :Isa(Me => HashRef[Table] => HashRef[Table] => ArrayRef[Str]) {
	my ($self, @models) = @_;

}

# Информация о таблицах в формате: table => Table
sub structure {
	my ($self) = @_;
	
	my $dbh = $self->connect;
	my $tables_sth = $dbh->table_info(undef, undef, '%', 'TABLE');

	my %table_row;
	while (my $row = $tables_sth->fetchrow_hashref) {
		my $table = $row->{TABLE_NAME};
		$table_row{$table} = $row;
	}

	$tables_sth->finish;

	my %table;
	for my $table (keys %table_row) {
		
		my $column_sth = $dbh->column_info(undef, undef, $row->{TABLE_NAME}, '%');
		
		while (my $col = $column_sth->fetchrow_hashref) {
		    print "Колонка: " . $col->{COLUMN_NAME} . "\n";
		    print "  Тип данных: " . $col->{TYPE_NAME} . "\n";
		    print "  Размер:     " . $col->{COLUMN_SIZE} . "\n";
		}
	
		$column_sth->finish;

		$table{$table} = Table->new(table => $table, column => , );
	}
	
	$self->finish($dbh);

	\%table
}

# 
sub word {
	my ($self, $word) = @_;
	$self->adapter->word($word);
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

# устанавливает OTHER
sub set_other {
	my $self = shift;
	$self->{OTHER} = [@_];
	$self
}

# опции таблицы
sub show_definition_table {
	my ($self, $tab, $create) = @_;
	
	join " ",
		defined($tab->autoincrement)? "AUTO_INCREMENT=" . $tab->autoincrement: (),
		defined($tab->charset)? 
			($create? "DEFAULT": "CONVERT TO",
			"CHARACTER SET", $self->quote($tab->charset), "COLLATE", $self->quote($tab->collation)): (),
		defined($tab->engine)? "ENGINE=" . $tab->engine: (),
		defined($tab->autoincrement)? "AUTO_INCREMENT=" . $tab->autoincrement: (),
		defined($tab->options)? $tab->options: (),
		defined($tab->comment)? $self->COMMENT($tab->comment, "tab"): (),
}

# внутренности таблицы
sub show_create_definition {
	my ($self, $tab) = @_;
	join(",\n",
		(map { $self->show_column($_, 1) } @{$tab->columns}),
		(map { $self->show_index($_) } @{$tab->indexes}),
		(map { $self->show_foreign($_) } @{$tab->foreigns}),
	);
}

# создать таблицу
sub show_create_table {
	my ($self, $tab) = @_;
	return
		join("", "CREATE TABLE ", $self->word($tab->name), " (\n", $self->show_create_definition($tab), "\n) ", $self->show_definition_table($tab, 1)),
		@{$self->{OTHER}};
}

# модифицировать опции таблицы
sub show_modify_table {
	my ($self, $tab) = @_;
	join "", "ALTER TABLE ", $self->word($tab->name), " ", $self->show_definition_table($tab);
}

# переименовать таблицу
sub show_rename_table {
	my ($self, $tab, $to) = @_;
	join "", "ALTER TABLE ", $self->word($tab->name), " RENAME TO ", $self->word($to);
}

# удалить таблицу
sub show_drop_table {
	my ($self, $tab) = @_;
	join "", "DROP TABLE ", $self->word($tab->name);
}

# удалить таблицу
sub show_truncate_table {
	my ($self, $tab) = @_;
	join "", "TRUNCATE TABLE ", $self->word($tab->name);
}


#@category DDL столбцов


# возвращает колумн из info без названия столбца
sub show_definition_column {
	my ($self, $col, $with_keys) = @_;
	join " ", $col->type,
		$with_keys? (
			$col->null || $col->pk? (): "NOT NULL",
		): (
			$col->null? (): "NOT NULL",
		),
		defined($col->default)? ("DEFAULT ", $self->quote($col->default)): (),
		$with_keys? (
			$col->pk? "PRIMARY KEY": (),
			$col->autoincrement? $self->AUTO_INCREMENT: (),
		): (),
		#$sql->{extra} ne ""? uc " $sql->{extra}": (),
		defined($col->comment)? $self->COMMENT($col->comment, "col"): (),
	;
}

# столбец с названием
sub show_column {
	my ($self, $col, $with_keys) = @_;
	join " ", $self->word($col->name), $self->show_definition_column($col, $with_keys)
}

# создать столбец
sub show_create_column {
	my ($self, $col, $after) = @_;
	join "", "ALTER TABLE ", $self->word($col->tab), " ADD COLUMN ", 
		$self->show_column($col),
		$self->show_after_column($after)
}

# изменить столбец
sub show_modify_column {
	my ($self, $col, $after) = @_;
	join "", "ALTER TABLE ", $self->word($col->tab), " MODIFY COLUMN ", 
		$self->show_column($col),
		$self->show_after_column($after)
}

# после
sub show_after_column {
	my ($self, $after) = @_;
	return "" if !defined $after;
	return " FIRST" if $after == 1;
	join "", " AFTER ", $self->word(ref $after? $after->name: $after)
}

# переименовать столбец
sub show_rename_column {
	my ($self, $col, $to) = @_;
	join "", "ALTER TABLE ", $self->word($col->tab), " CHANGE ", $self->word($col->name), " ", $self->word($to), " ", $self->show_definition_column($col->clone->load);
}

# удалить столбец
sub show_drop_column {
	my ($self, $col) = @_;
	join "", "ALTER TABLE ", $self->word($col->tab), " DROP ", $self->word($col->name);
}


#@category DDL индексов



# формирует индекс без его названия
sub show_definition_index {
	my ($self, $idx) = @_;
	join "", "(", join(", ", map { $self->word($_) } @{$idx->cols}), ")",
		defined($idx->comment)? (" ", $self->COMMENT($idx->comment, "idx")): ();
}

# индекс c типом и названием
sub show_index {
	my ($self, $idx) = @_;
	join "", $idx->type, ($idx->type ne "INDEX"? " KEY": ()), " ", $self->word($idx->name), " ", $self->show_definition_index($idx);
}

# формирует индекс из info
sub show_create_index {
	my ($self, $idx) = @_;
	join "", "ALTER TABLE ", $self->word($idx->tab), " ADD ", $self->show_index($idx)
}

# изменяет индекс
sub show_modify_index {
	my ($self, $idx) = @_;	
	join "", $self->show_drop_index($idx), ", ADD ", $self->show_index($idx->clone->upd);
}

# переименовывает индекс
sub show_rename_index {
	my ($self, $idx, $to) = @_;
	$to = $idx->clone->name($to) if !ref $to;
	join "", $self->show_drop_index($idx), ", ADD ", $self->show_index($to->clone->upd);
}

# удалить индекс
sub show_drop_index {
	my ($self, $idx) = @_;
	join "", "ALTER TABLE ", $self->word($idx->tab), " DROP INDEX ", $self->word($idx->name)
}


#@category DDL ссылок

# формирует индекс без его названия
sub show_definition_foreign {
	my ($self, $fk) = @_;
	join "", "FOREIGN KEY (", join(", ", map { $self->word($_) } @{$fk->cols}), ") REFERENCES ",
		$self->word($fk->ref_tab), " (", join(", ", map { $self->word($_) } @{$fk->refs}), ")",
		defined($fk->on_update)? (" ON UPDATE ", $fk->on_update): (),
		defined($fk->on_delete)? (" ON DELETE ", $fk->on_delete): ();
}

# индекс c типом и названием
sub show_foreign {
	my ($self, $fk) = @_;
	join "", "CONSTRAINT ", $self->word($fk->name), " ", $self->show_definition_foreign($fk);
}

# создаёт ссылку
sub show_create_foreign {
	my ($self, $fk) = @_;
	join "", "ALTER TABLE ", $self->word($fk->tab), " ADD ", $self->show_foreign($fk)
}

# модифицирует
sub show_modify_foreign {
	my ($self, $fk) = @_;
	return $self->show_drop_foreign($fk), 
		$self->show_create_foreign($fk);
	#join "", "ALTER TABLE ", $self->word($fk->tab), " DROP FOREIGN KEY ", $self->word($fk->name), "; ", ", ADD ", $self->show_foreign($fk)
}

# переименовывает fk
sub show_rename_foreign {
	my ($self, $fk, $to) = @_;
	$to = $fk->clone->name($to) if !ref $to;
	join "", "ALTER TABLE ", $self->word($fk->tab), " DROP FOREIGN KEY ", $self->word($fk->name), ", ADD ", $self->show_foreign($to)
}

# удаляет ссылку
sub show_drop_foreign {
	my ($self, $fk) = @_;
	join "", "ALTER TABLE ", $self->word($fk->tab), " DROP FOREIGN KEY ", $self->word($fk->name)
}

1;