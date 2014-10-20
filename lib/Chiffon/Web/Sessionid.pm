package Chiffon::Web::Sessionid;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_SESSIONID_DEBUG} || 0;

# URL: /sessionid
sub start {

  my $self      = shift;
  $self->config->{navigator_endpoint} =~ /(http:\/\/.+?)\/.*/;
  my $url = $1 . '/session_id/' . $self->user_name;

  my $tx = $self->ua->get($url);

  my $logger = $self->app->log;
  warn $tx->res->body;
  $self->render(text=>$tx->res->body);
}

1;
