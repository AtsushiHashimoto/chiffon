package Chiffon::Web::Logger;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_LOGGER_DEBUG} || 0;


# URL : /logger(/start)?
sub start {
  my $self   = shift;
  my $logger = $self->app->log;
  my $type   = $self->param('type') // '';
  my $msg    = $self->param('msg') // '';
  if ($type =~ /(debug|info|warn|error|fatal)/) {
    $logger->$type($msg);
  }
  else {
    my $msg = 'missing or invalid type for logger';
    $logger->error($msg);
    $self->render(json => {'status' => $msg});
    return;
  }

  $self->render(json => {status => 'success', body => []});
}

1;
