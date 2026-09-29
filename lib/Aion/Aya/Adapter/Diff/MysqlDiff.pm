package Aion::Aya::Adapter::Diff::MysqlDiff;

use common::sense;

use aliased 'Aion::Aya::Model';
use aliased 'Aion::Aya::Table';
use aliased 'Aion::Annotation::Reader' => 'AnnotationReader';

use Aion;

extends 'Aion::Aya::Adapter::Diff::MemDiff';

# Заполняет таблицу на основе модели
sub model2table :Isa(Me => Model => Table) {
	my ($self, $model) = @_;

	my %remark;
	my $reader = AnnotationReader->new(AnnotationReader->READ_REMARKS);
	while(<$reader>) {
		$remark{$_->{pkg}}{$_->{name}} = $_->{remark} if exists $model->{$_->{pkg}};
	}
	undef $reader;
	
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
			options => $col->{options} // [],
			comment => $remark{$field->{pkg}}{$name} // '',
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

1;