package Chiffon::Web::System;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_SYSTEM_DEBUG} || 0;


# URL: /system(/start)?
sub start {
  my $self = shift;
  $self->redirect_to('/login');
}

# URL: (/system)?/login
sub login {
  my $self = shift;
  my $logger  = $self->app->log;

  $self->session(alive => 1);
  my $session_name = $self->session('user_id') || '';

  # 認証済みの場合はリダイレクト
  my $back_url = $self->param('back_url') || '/';
  return $self->redirect_to($back_url) if $session_name ne '';

  # getの場合は検証せずに表示
  $self->add_stash_message(
    { type => 'message',
      msg  => 'PLEASE LOGIN'
    }
  );
  return if $self->req->method eq 'GET';

  $self->add_stash_message(
    { type => 'error',
      msg =>
        'INVALID USERNAME OR PASSWORD.'
    }
  );

  # フォーム入力を検証
  my $user_id  = $self->param('user_id') || '';
  my $password = $self->param('pw')      || '';
  return if ($user_id eq '' or $password eq '');
  return unless $user_id =~ /\A\w+\z/ms;

  # ユーザー情報を検証
  my $user = $self->get_user($user_id);
  $logger->debug($self->dumper($user)) if DEBUG;
  return unless defined $user;
  return unless $self->csh_validate($user->{salted}, $password);

  # 認証済み
  $self->reset_stash_message;
  $self->add_stash_message(
    { type => 'success',
      msg  => qq{Welcome ${user_id}!},
    },
  );
  $self->stash2flash;
  $self->session(user_id => $user_id);    # セッションにIDをセット
  return $self->redirect_to($back_url);
}

# URL: (/system)?/logout
sub logout {
  my $self = shift;
  $self->session(user_id => '');
  $self->add_stash_message(
    { type => 'info',
      msg  => qq{THANKS},
    },
  );
  $self->stash2flash;
  $self->flash(back_url => '/',);
  return $self->redirect_to('/login');
}

1;

sub auth {
  my $self = shift;

  $self->flash(
    message => {
      type => 'info',
      msg =>
        q{TIMEOUT. LOGIN AGAIN},
    }
  ) unless defined $self->session('alive');
  $self->session(alive => 1);
  my $user = $self->get_user;
  my $back_url = $self->param('back_url') || $self->req->url->to_string;
  $back_url = '/' if $back_url =~ /logout/;
  $self->flash(back_url => $back_url);

  unless ($user) {
    $self->redirect_to('/login');
    return
      ; # redirect_toを同時に返すと「真」が返るため別で処理する
  }
  return 1;
}

1;
