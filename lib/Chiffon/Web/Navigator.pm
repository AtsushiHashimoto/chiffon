package Chiffon::Web::Navigator;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_NAVIGATOR_DEBUG} || 0;

# URL : /navigator/start
sub start {
  my $self = shift;
  my $logger = $self->app->log;
  my $recipe_xml_file = $self->recipe_xml_file;
  unless ($recipe_xml_file) {
    my $msg = 'missing recipe_xml_file';
    $logger->fatal($msg);# 必ず値があるはず
    return $self->render_exception($msg);
  }

  # Navigator と通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'START',
      operation_contents => scalar $recipe_xml_file->slurp,
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $navigator_response);
}

# URL : /navigator/channel/(overview|materials|guide)
sub channel {
  my $self = shift;
  my $logger = $self->app->log;
  my $id = $self->param('id') // '';
  if ($id eq '') {
    my $msg = 'missing channel id';
    $logger->fatal($msg);
    return $self->render_exception($msg);
  }
  if ($id !~ /\A(overview|materials|guide)\z/) {
    my $msg = 'unknown channel id';
    $logger->fatal($msg);
    return $self->render_exception($msg);
  }

  # Navigatorと通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'CHANNEL',
      operation_contents => uc $id,
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $navigator_response);
}

# URL : /navigator/navi_menu
sub navi_menu {
  my $self = shift;
  my $logger = $self->app->log;
  my $id = $self->param('id') // '';
  if ($id eq '') {
    my $msg = 'missing navi_menu id';
    $logger->fatal($msg);
    return $self->render_exception($msg);
  }

  # Navigatorと通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'NAVI_MENU',
      operation_contents => $id,
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $navigator_response);
}

# URL : /navigator/navi_menu
sub check {
  my $self = shift;
  my $logger = $self->app->log;
  my $id = $self->param('id') // '';
  if ($id eq '') {
    my $msg = 'missing check id';
    $logger->fatal($msg);
    return $self->render_exception($msg);
  }

  # Navigatorと通信
  my $navigator_response = $self->post_to_navigator(
    {
      situation => 'CHECK',
      operation_contents => $id,
    }
  );
  warn qq{-- @{[$self->dumper($navigator_response)]} } if DEBUG;
  $self->render(json => $navigator_response);
}

1;
