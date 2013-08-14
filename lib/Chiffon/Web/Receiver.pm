package Chiffon::Web::Receiver;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_RECEIVER_DEBUG} || 0;

# URL: /receiver(/start)?
sub start {
  my $self      = shift;
  my $sessionid = $self->param('sessionid') // '';
  my $string    = $self->param('string') // '';

  if ($sessionid eq '') {
    $self->render_exception('sessionid required');
    return;
  }
  if ($string eq '') {
    $self->render_exception('string required');
    return;
  }

  my $ws_clients = $self->app->ws_clients;
  warn qq{-- ws_clients : @{[keys %{$ws_clients}]} } if DEBUG;
  for my $client (values %{$ws_clients}) {
    $client->send({json => {sessionid => $sessionid, string => $string,}});
  }

  $self->render(json => {status => 'success'});
}

1;
