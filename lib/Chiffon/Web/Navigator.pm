package Chiffon::Web::Navigator;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_NAVIGATOR_DEBUG} || 0;

# URL : /navigator/start
sub start {
  my $self = shift;
  my $logger = $self->app->log;
  my $recipe_xml_file = $self->recipe_xml_file;
  unless ($recipe_xml_file) {
    $logger->fatal('missing recipe_xml_file');# 必ず値があるはず
    return $self->render_exception;
  }

  # Navigator と通信
  my $situation = 'START';
  my $operation_contents = $recipe_xml_file->slurp;
  my $navigator_response = $self->post_to_navigator(
    {
      situation => $situation,
      operation_contents => $operation_contents
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $self->app->json->decode($navigator_response->body));
}

# URL : /navigator/overview
sub overview {
  my $self = shift;

  # Navigatorと通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'CHANNEL',
      operation_contents => 'OVERVIEW',
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $self->app->json->decode($navigator_response->body));
}

# URL : /navigator/materials
sub materials {
  my $self = shift;

  # Navigatorと通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'CHANNEL',
      operation_contents => 'MATERIALS',
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $self->app->json->decode($navigator_response->body));
}

# URL : /navigator/guide
sub guide {
  my $self = shift;

  # Navigatorと通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'CHANNEL',
      operation_contents => 'GUIDE',
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $self->app->json->decode($navigator_response->body));
}

# URL : /navigator/navi_menu
sub navi_menu {
  my $self = shift;
  my $logger = $self->app->log;
  my $id = $self->param('id');
  unless (defined $id) {
    $logger->fatal('missin navi_menu id');
    return $self->render_exception;
  }

  # Navigatorと通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'NAVI_MENU',
      operation_contents => $id,
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $self->app->json->decode($navigator_response->body));
}

# URL : /navigator/navi_menu
sub check {
  my $self = shift;
  my $logger = $self->app->log;
  my $id = $self->param('id');
  unless (defined $id) {
    $logger->fatal('missin check id');
    return $self->render_exception;
  }

  # Navigatorと通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'CHECK',
      operation_contents => $id,
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $self->app->json->decode($navigator_response->body));
}

1;
