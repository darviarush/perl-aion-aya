package Aion::Aya::Adapter::SQL;

use common::sense;

use aliased 'Aion::Aya::Query';
use aliased 'Aion::Aya::Iterator';

use Aion;

with 'Aion::Aya::Adapter';
with 'Aion::Aya::Adapter::Role::SQLRole';
with 'Aion::Aya::Adapter::Role::DbSyncRole';

# Сохранение в базу
sub save {
	my ($self, $pool) = @_;

	$pool //= $Aion::Model::Connects::connects;

	my $connect = $pool->get;
	my $guard = Guard::guard { $pool->put($connect) };

	my $pkg = ref $self;
	my $meta = $Aion::META{$pkg};
	my $table = $meta->{table};
	my $features = $meta->{feature};
	my $pkfields = $meta->{primary_key}{fields};
	my $pk = $pkfields->[0];

	# Если есть pk – update, иначе – insert и установка pk

	if ($self->has($pk)) {
		my @set;
		for my $feature (sort { $a->{order} <=> $b->{order} } values %$features) {
			if($feature->{col} and $self->has($feature->{name})) {
				my $name = $feature->{name};
				my $value = $self->$name;
				push @set, sprintf "%s = %s", $connect->word($feature->{col}), $connect->quote($value, $feature->{isa});
			}
		}

		my $where = join " AND ", map {
			my $feature = $features->{$_};
			sprintf "%s = %s", $connect->word($feature->{col}), $connect->quote($value, $feature->{isa})
		} @$pkfields;

		$connect->do("UPDATE ${\$connect->word($table)} SET ${\join ', ', @set} WHERE $where");
	} else {
    	my @fields;
    	my @values;
    	for my $feature (sort { $a->{order} <=> $b->{order} } values %$features) {
    		if($feature->{col} and $self->has($feature->{name})) {
    			my $name = $feature->{name};
    			my $value = $self->$name;
                push @fields, $connect->word($feature->{col});
                push @values, $connect->quote($value, $feature->{isa});
    		}
    	}

		$connect->do("INSERT INTO ${$connect->word($table)\} (${\join ', ', @fields}) VALUES (${\join ', ', @values})");

		if(0 == @$pkfields && $features->{$pk}{auto_increment}) {
			$self->{$pk} = $connect->do("LAST_INSERT_ID()");
		}
	}
}

1;