package Aion::Aya::Adapter::Diff::Abstract;

use common::sense;

use aliased 'Aion::Aya::Model';
use aliased 'Aion::Aya::Table';

use Aion;

# Адаптер
has adapter => (is => 'ro+', isa => 'Aion::Aya::Adapter');

# Сравнивает два списка таблиц, возвращает инструкции DQL, которые нужно выполнить, чтобы привести к 1-й
sub diff :Isa(Me => HashRef[Table] => HashRef[Table] => ArrayRef[Str]);

# Информация о таблицах
sub structure :Isa(Me => HashRef[Table]);

# Заполняет таблицу на основе модели
sub model2table :Isa(Me => Model => Table) {
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
			# TODO: дописать остальные. Они в типе Aion::Aya::Model->Column
		);

		push @columns, \%column;
	}

	Table->new(
		table => $model->table,
		columns => \@columns,
	);
}

1;