package Chiffon::Web::Index;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_INDEX_DEBUG} || 0;

use Path::Class qw(file dir);


# URL : /
sub start {
  my $self = shift;
  my $logger = $self->app->log;

  my $config = $self->config;
  my @pathes = dir($config->{recipes_dir})->children;
  $logger->debug($self->dumper(\@pathes)) if DEBUG;

  my @recipes;
  for my $path (@pathes) {
    next unless $path->is_dir;
    push @recipes, $path;
  }
  $self->stash(recipes => \@recipes);

  $self->render(
    layout => 'default',
    title => 'Recipe List',
  );
}

1;
