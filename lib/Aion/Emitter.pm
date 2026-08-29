package Aion::Emitter;
# Паб-саб эмиттер событий

use common::sense;

use Aion;

# Слушатели: имя события (класс) => список колбэков
has _listeners => (is => 'ro-', isa => HashRef[ArrayRef], lazy => 0, default => sub { +{} });

# Подписаться на событие по имени (классу события)
sub on {
	my ($self, $name, $code) = @_;
	push @{$self->{_listeners}{$name}}, $code;
	$self;
}

# Рассылает событие слушателям его класса и всех предков
sub emit {
	my ($self, $event) = @_;

	my @queue = (ref $event);
	my %seen;
	while (@queue) {
		my $name = pop @queue;
		next if $seen{$name}++;
		$_->($event) for @{$self->{_listeners}{$name}};
		my @ancestors = @{"${name}::ISA"};
		push @queue, @ancestors if @ancestors;
	}

	$self;
}

1;
