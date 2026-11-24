!ru:en
# NAME

Aion::Aya::Adapter::Transform::Abstract - контракт для превращения Aion::Aya::Query в запрос к БД (Mysql, Elastic, etc)

# SYNOPSIS

```perl
package ExEntity {
	use Aion with => 'Aion::Aya';
}

package ExTransform {
	use aliased 'Aion::Aya::Query';

	use Aion;

	with 'Aion::Aya::Adapter::Transform::Abstract';

	sub transform :Isa(Me => Query => Any) {
		my ($self, $query) = @_;
		+{ x => 123 }
	}
}

use aliased 'Aion::Aya::Query';

my $transformator = ExTransform->new;
my $query = Query->new(from => 'ExEntity');
$transformator->transform($query) # --> +{ x => 123 }
```

# DESCRIPTION

Aion::Aya::Adapter::Transform::Abstract - контракт для превращения Aion::Aya::Query в запрос к БД (Mysql, Elastic, etc).

# SUBROUTINES

## transform ()

Трансформирует запрос в промежуточное представление (например, SQL или структуру у Elastic).

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **Perl5**

# COPYRIGHT

The Aion::Aya::Adapter::Transform::Abstract module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
