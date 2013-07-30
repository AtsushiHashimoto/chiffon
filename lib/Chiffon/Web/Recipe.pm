package Chiffon::Web::Recipe;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_RECIPE_DEBUG} || 0;

use Path::Class qw(file dir);


# URL : /recipe
sub start {
  my $self = shift;
  my $logger = $self->app->log;

  my $config = $self->config;
  my $name = $self->param('name');
  my $recipe_file = file($config->{recipes_dir}, $name, 'recipe.xml');
  $logger->debug($recipe_file) if DEBUG;
  my $xml = $self->app->xml;
  my $recipe = $xml->XMLin($recipe_file->stringify);

  $self->stash(recipe => $recipe);

  $self->render(
    layout => 'default',
    title => $recipe->{title},
  );
}

1;
