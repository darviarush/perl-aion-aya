package Aion::Aya::Adapter::Diff::DDL;
# DDL - отдельный класс, а не роль.
# Он получает adapter в качестве сессии для запросов.
# Имеет

use common::sense;

use aliased 'Aion::Aya::Model';

use Aion;

with 'Aion::Aya::Adapter::Diff::Abstract';

# Сравнивает модели и базу
sub diff :Isa(Me => Array[ClassName] => Str) {
	my ($self, @models) = @_;

	Model->load;
	
	@entities = Model->models unless @models;
	
	my $dbh = $self->connect;
	my $tables_sth = $dbh->table_info(undef, undef, '%', 'TABLE');

	my %table;
	while (my $row = $tables_sth->fetchrow_hashref) {
		$table{$row->{TABLE_NAME}} = $row;
	}

	$tables_sth->finish;

	for my $entity (@models) {
		my $model = Model->get($entity);

		if(exists $table{$model->}) {
		
			my $column_sth = $dbh->column_info(undef, undef, $row->{TABLE_NAME}, '%');
			
			while (my $col = $column_sth->fetchrow_hashref) {
			    print "Колонка: " . $col->{COLUMN_NAME} . "\n";
			    print "  Тип данных: " . $col->{TYPE_NAME} . "\n";
			    print "  Размер:     " . $col->{COLUMN_SIZE} . "\n";
			}
		
			$column_sth->finish;
		}
		else {
			# Сформировать CREATE TABLE
		}
	}
	
	$self->finish($dbh);
}

# Информация о таблице из базы
sub table_info {
	my ($self, $table) = @_;

	my $query = "";
	
	
	$self->adapter->prepare($dbh, $query);
	
}

1;