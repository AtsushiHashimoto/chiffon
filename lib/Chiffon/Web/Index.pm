package Chiffon::Web::Index;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub start {
  my $self = shift;

  $self->render(
    layout => 'default',
    title => 'Hello World',
  );
}

1;
