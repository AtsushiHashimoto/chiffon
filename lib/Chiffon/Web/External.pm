package Chiffon::Web::External;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;

use constant DEBUG => $ENV{CHIFFON_WEB_EXTERNAL_DEBUG} || 0;

sub start {
  my $self       = shift;
  my $ws_clients = $self->app->ws_clients;
  warn qq{-- ws_clients : @{[keys %{$ws_clients}]} } if DEBUG;

  Mojo::IOLoop->stream($self->tx->connection)->timeout(300);

  my $id = sprintf '%s', $self->tx;
  warn qq{-- id : $id } if DEBUG;
  $ws_clients->{$id} = $self->tx;

  # JSONのメッセージ
  $self->on(
    json => sub {
      my ($self, $json) = @_;
      warn qq{-- fired : json } if DEBUG;
      $self->send({json => {status => 'success'}});
    }
  );

  $self->on(
    finish => sub {
      my ($self, $code, $reason) = @_;
      warn qq{-- fired : finish } if DEBUG;
      return unless $self;
      my $id = sprintf '%s', $self->tx;
      warn qq{-- id : $id } if DEBUG;
      my $ws_clients = $self->app->ws_clients;
      delete $ws_clients->{$id};
    }
  );

}

1;
