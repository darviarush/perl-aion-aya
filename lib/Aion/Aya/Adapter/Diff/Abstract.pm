package Aion::Aya::Adapter::Diff::Abstract;

use common::sense;

use Aion;

# Адаптер
has adapter => (is => 'ro+', isa => 'Aion::Aya::Adapter');

# Сравнивает модели и структуру базы
sub diff :Isa(Me => ArrayRef[ClassName] => Any);

# Заполняет столбцы таблицы на основе модели
sub build_columns {
	my ($cls, $model) = @_;

	my $feature_href = $Aion::META{$model->{pkg}}{feature}; 

	my @columns;
	
	for my $field (%{$model->{field}}) {
		my $feature = $feature_href->{$field};
		my $isa = $feature->{isa};
		my $is_nullable = $isa->{name} eq 'Maybe'? do { $isa = $isa->{args}[0]; 1 }: 0;
		my %column = (
			name => $model->col_name(),
			is_nullable => $is_nullable,
		);

		push @columns, \%column;
	}

	$model->columns(\@columns);
}

1;