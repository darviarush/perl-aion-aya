package Aion::Aya::Table;
# Таблица описывающая таблицу реляции в базе

use common::sense;

use List::Util qw//;

use Aion;

BEGIN {
	my %COLUMN = (
		name => Str,
		type => Str,
		is_nullable => Bool,
		default => Str,
		options => Str,
		comment => Str,
		order => Num,
	);

	subtype 'OptionColumn', as Dict[List::Util::pairmap { ($a => Option[$b]) } %COLUMN];
	
	subtype 'Column', as Dict[%COLUMN];

	# У первичного ключа нет имени
	subtype 'PrimaryKey', as Dict[
		columns => ArrayRef[Str],
		options => ArrayRef[Str],
	];

	subtype 'Key', as Dict[
		name => Str,
		columns => ArrayRef[Str],
		options => ArrayRef[Str],
	];

	subtype 'ForeignKey', as Dict[
		name => Str,
		to_table => PackageName,
		columns => ArrayRef[Str],
		to_columns => ArrayRef[Str],
		options => ArrayRef[Str],
	];
}

# Имя таблицы в базе
has table => (is => 'ro+', isa => Str);

# Опции таблицы в базе
has options => (is => 'ro', isa => Undef|Str|ArrayLike|HashLike);

# Первичный ключ
has primary_key => (is => 'ro+', isa => PrimaryKey);

# Столбцы
has columns => (is => 'ro+', isa => ArrayRef[Column]);

# Уникальные ключи
has unique_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Индексы
has index_keys => (is => 'ro', isa => ArrayRef[Key], lazy => 0, default => sub {+[]});

# Внешние ключи
has foreign_keys => (is => 'ro', isa => ArrayRef[ForeignKey], lazy => 0, default => sub {+[]});

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Table - снимок структуры таблицы в базе: столбцы, ключи и внешние связи

=head1 SYNOPSIS

	use Aion::Aya::Table;
	
	my $table = Aion::Aya::Table->new(
		table => 'book',
		primary_key => {columns => ['id'], options => []},
		columns => [
			{name => 'id', type => 'int', is_nullable => 0, default => '', options => 'auto_increment', comment => '', order => 0},
			{name => 'title', type => 'varchar(255)', is_nullable => 0, default => '', options => '', comment => 'Название', order => 1},
		],
		unique_keys => [{name => 'unq_book_title', columns => ['title'], options => []}],
		index_keys => [{name => 'idx_book_title', columns => ['title'], options => []}],
		foreign_keys => [{
			name => 'fk_book_author',
			to_table => 'author',
			columns => ['author_id'],
			to_columns => ['id'],
			options => ['on delete cascade'],
		}],
		options => 'ENGINE=InnoDB',
	);
	
	$table->table                          # -> 'book'
	$table->primary_key->{columns}->[0]    # -> 'id'
	scalar(@{$table->columns})             # -> 2
	$table->columns->[1]->{name}           # -> 'title'
	$table->columns->[1]->{comment}        # -> 'Название'
	$table->unique_keys->[0]->{name}       # -> 'unq_book_title'
	$table->index_keys->[0]->{name}        # -> 'idx_book_title'
	$table->foreign_keys->[0]->{to_table}  # -> 'author'
	$table->foreign_keys->[0]->{options}->[0] # -> 'on delete cascade'
	$table->options                        # -> 'ENGINE=InnoDB'

Обязательные поля — C<table>, C<primary_key> и C<columns>; их отсутствие даёт исключение:

	use Aion::Aya::Table;
	
	Aion::Aya::Table->new(columns => []) # @-> table required

=head1 DESCRIPTION

C<Aion::Aya::Table> — общий формат описания структуры таблицы. Один и тот же объект получается двумя путями:

=over

=item * из модели (C<< Migration::Comparator-E<gt>model2table >>) — по метаданным C<%Aion::Aya::META>;

=item * из базы (C<< Migration::Comparator-E<gt>structure >>) — по системным каталогам C<DBI>.

=back

C<diff> сравнивает два C<HashRef[Aion::Aya::Table]> (модель и базу) и возвращает DDL-инструкции, которые приводят базу к модели. Поэтому именно здесь живёт контракт между метаданными, драйвером и миграциями.

=head1 FEATURES

=head2 table

Имя таблицы в базе.

=head2 options

Опции таблицы в базе.

=head2 primary_key

Первичный ключ.

=head2 columns

Столбцы.

=head2 unique_keys

Уникальные ключи.

=head2 index_keys

Индексы.

=head2 foreign_keys

Внешние ключи.

=head1 TYPES

=head2 Column

Столбец таблицы. Все поля обязательны.

=over

=item * C<name> — имя в базе;

=item * C<type> — тип SQL (C<int>, C<varchar(255)>);

=item * C<is_nullable> — допускает C<NULL>;

=item * C<default> — значение по умолчанию;

=item * C<options> — дополнительные опции (C<auto_increment>, C<unsigned>);

=item * C<comment> — комментарий;

=item * C<order> — порядок в определении.

=back

	my $col = {name => 'id', type => 'int', is_nullable => 0, default => '', options => 'auto_increment', comment => '', order => 0};
	
	$col ~~ Aion::Aya::Table::Column() # -> 1
	
	# Без обязательного поля type
	my %no_type = %$col; delete $no_type{type};
	\%no_type ~~ Aion::Aya::Table::Column() # -> ''
	
	# Лишнее поле
	my %extra = (%$col, extra => 1);
	\%extra ~~ Aion::Aya::Table::Column() # -> ''
	
	# Неверный тип поля
	my %bad_type = (%$col, is_nullable => 'maybe');
	\%bad_type ~~ Aion::Aya::Table::Column() # -> ''

=head2 OptionColumn

То же, что C<Column>, но все поля необязательны — для чтения из базы, где часть сведений недоступна.

	my $empty = {};
	$empty ~~ Aion::Aya::Table::OptionColumn() # -> 1
	
	my $name_only = {name => 'id'};
	$name_only ~~ Aion::Aya::Table::OptionColumn() # -> 1
	
	my $name_type = {name => 'id', type => 'int'};
	$name_type ~~ Aion::Aya::Table::OptionColumn() # -> 1
	
	# Тип проверяется, если поле задано
	my %bad = (is_nullable => 'maybe');
	\%bad ~~ Aion::Aya::Table::OptionColumn() # -> ''

=head2 PrimaryKey

Первичный ключ. В отличие от C<Key>, у него нет имени — в базе первичный ключ один.

=over

=item * C<columns> — список столбцов;

=item * C<options> — опции (C<using> и т. п.).

=back

	my $pk = {columns => ['id'], options => []};
	
	$pk ~~ Aion::Aya::Table::PrimaryKey() # -> 1
	
	# Составной первичный ключ
	my $composite_pk = {columns => ['author', 'title'], options => []};
	$composite_pk ~~ Aion::Aya::Table::PrimaryKey() # -> 1
	
	# Без столбцов
	my $no_cols = {options => []};
	$no_cols ~~ Aion::Aya::Table::PrimaryKey() # -> ''
	
	# Имени у первичного ключа нет
	my $named = {name => 'pk', columns => ['id'], options => []};
	$named ~~ Aion::Aya::Table::PrimaryKey() # -> ''

=head2 Key

Ключ таблицы: уникальный или обычный индекс.

=over

=item * C<name> — имя ключа;

=item * C<columns> — список столбцов;

=item * C<options> — опции (C<using> и т. п.).

=back

	my $key = {name => 'idx_xy', columns => ['pos_history', 'pos_action'], options => []};
	
	$key ~~ Aion::Aya::Table::Key() # -> 1
	
	# Без имени
	my %no_name = %$key; delete $no_name{name};
	\%no_name ~~ Aion::Aya::Table::Key() # -> ''
	
	# Столбцы — не массив строк
	my %not_array = (%$key, columns => 'pos_history');
	\%not_array ~~ Aion::Aya::Table::Key() # -> ''
	
	
	# Составной ключ
	my $composite = {name => 'pk', columns => ['author', 'title'], options => []};
	$composite ~~ Aion::Aya::Table::Key() # -> 1

=head2 ForeignKey

Внешний ключ.

=over

=item * C<name> — имя ограничения;

=item * C<to_table> — таблица назначения;

=item * C<columns> — столбцы текущей таблицы;

=item * C<to_columns> — столбцы таблицы назначения;

=item * C<options> — опции (C<on delete cascade>).

=back

	my $fk = {name => 'fk_book_author', to_table => 'author', columns => ['author_id'], to_columns => ['id'], options => ['on delete cascade']};
	
	$fk ~~ Aion::Aya::Table::ForeignKey() # -> 1
	
	# Без таблицы назначения
	my %no_table = %$fk; delete $no_table{to_table};
	\%no_table ~~ Aion::Aya::Table::ForeignKey() # -> ''
	
	# Таблица назначения должна быть именем пакета
	my %bad_table = (%$fk, to_table => 'Author Table');
	\%bad_table ~~ Aion::Aya::Table::ForeignKey() # -> ''
	
	# Неверные столбцы
	my %bad_cols = (%$fk, to_columns => 'id');
	\%bad_cols ~~ Aion::Aya::Table::ForeignKey() # -> ''

Все пять типов — C<Dict>, то есть проверяются при установке: незаявленный ключ или неверный тип дают исключение.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Table module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
