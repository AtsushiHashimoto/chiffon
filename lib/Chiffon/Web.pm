package Chiffon::Web;
use Mojo::Base 'Mojolicious';

our $VERSION = "0.01";

BEGIN {
  $ENV{MOJO_I18N_DEBUG} = 0;
  $ENV{CHIFFON_WEB_SYSTEM_DEBUG} = 0;
  $ENV{CHIFFON_WEB_INDEX_DEBUG} = 1;
  $ENV{CHIFFON_WEB_RECIPE_DEBUG} = 1;
};

use Mojo::ByteStream qw(b);

use JSON::XS qw(encode_json decode_json);
use Crypt::SaltedHash;
use Path::Class qw(file dir);
use XML::Simple;

has xml => sub { XML::Simple->new };

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->secret(b(file(__FILE__)->absolute)->sha1_sum);

  # name
  $self->helper(brandname => sub { q{Chiffon Viewer} });

  # Plugins
  $self->plugin('config');
  $self->plugin('I18N',
    namespace => 'Chiffon::Web::I18N',
  );

  # helpers
  $self->helper(
    get_user => sub {
      my $self = shift;
      my $user_id = shift || $self->session('user_id');
      return unless defined $user_id;
      my $config = $self->config;
      my $home = $self->app->home;
      my $users = decode_json(file($home->detect, $config->{userfile})->slurp);
      return $users->{$user_id};
    }
  );

  # validate hash
  $self->helper(
    csh_validate => sub {
      my ($self, $salted, $plain) = @_;
      return Crypt::SaltedHash->validate($salted, $plain);
    }
  );



  # メッセージの管理
  # $self->add_stash_message(
  #   { type => 'success', # or 'warn', 'error', 'info', ''
  #     msg  => 'メッセージ',
  #   }
  # );
  $self->helper(
    add_stash_message => sub {
      my ($self, $msg) = @_;
      my $messages = $self->stash('message') // [];
      push @{$messages}, $msg;
      $self->stash(message => $messages);
    }
  );
  $self->helper(
    stash2flash => sub {
      my ($self) = @_;
      my $messages = $self->stash('message') // [];
      $self->stash(message => []);
      $self->flash(message => $messages);
    }
  );

  # メッセージをリセット
  $self->helper(
    reset_stash_message => sub {
      shift->stash(message => []);
    }
  );


  # Router
  my $r = $self->routes;

  # 認証なしでOKのルート
  # login
  $r->route('/login')->via(qw(get post))->to('system#login');

  # 認証
  $r = $r->bridge->to('system#auth');

  # 認証が必要なルート
  # ログアウト
  $r->route('/logout')->to('system#logout');

  # メニュー
  $r->via(qw(get post))->route(qq{/:controller/:action/:id}, id => qr/\d+/)
    ->to(controller => 'index', action => 'start', id => 0);
}

1;
__END__

=encoding utf-8

=head1 NAME

Chiffon - Project for Chiffon Recipe Viewer

=head1 SYNOPSIS

    $ hypnotoad script/chiffon_web

=head1 DESCRIPTION

Project for Chiffon Recipe Viewer.

=head1 INSTALL

    cpanm --installdeps .

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

* Nobutaka Wakabayashi
* Atsushi Hashimoto

=cut
