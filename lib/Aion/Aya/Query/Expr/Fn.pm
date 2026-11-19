package Aion::Aya::Query::Expr::Fn;

use common::sense;

use Aion;

with 'Aion::Aya::Query::Expr';

# Имя функции
has name => (is => 'ro', isa => Str);

# Аргументы
has args => (is => 'ro', isa => ArrayRef['Aion::Aya::Query::Expr']);

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Aya::Query::Expr::Fn - вызов функции базы в выражении

=head1 SYNOPSIS

	use Aion::Aya::Query::Expr::Val;
	use Aion::Aya::Query::Expr::Fn;
	
	my $arg = Aion::Aya::Query::Expr::Val->new(value => 'title');
	
	my $fn = Aion::Aya::Query::Expr::Fn->new(name => 'COUNT', args => [$arg]);
	
	$fn->name           # -> 'COUNT'
	$fn->args->[0]->value # -> 'title'
	$fn->isa('Aion::Aya::Query::Expr') # -> 1
	
	# Несколько аргументов
	my $coalesce = Aion::Aya::Query::Expr::Fn->new(
		name => 'COALESCE',
		args => [
			Aion::Aya::Query::Expr::Val->new(value => 1),
			Aion::Aya::Query::Expr::Val->new(value => 0),
		],
	);
	
	scalar(@{$coalesce->args}) # -> 2
	
	# Пустой список аргументов допустим
	my $now = Aion::Aya::Query::Expr::Fn->new(name => 'NOW', args => []);
	
	scalar(@{$now->args}) # -> 0

=head1 DESCRIPTION

Узел дерева выражений для вызова функции базы: C<name(args...)>. Аргументы — любые выражения (C<Val>, C<Field>, другие C<Fn>), список может быть пустым.

=head1 FEATURES

=head2 name

Имя функции базы (C<COUNT>, C<COALESCE>, C<LOWER>).

=head2 args

Список аргументов — выражений.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Aya::Query::Expr::Fn module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
