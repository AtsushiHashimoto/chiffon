package Chiffon::Web;
use Mojo::Base 'Mojolicious';

our $VERSION = "0.01";

BEGIN {
  $ENV{MOJO_I18N_DEBUG} = 0;
  $ENV{CHIFFON_WEB_DEBUG} = 1;
  $ENV{CHIFFON_WEB_INDEX_DEBUG} = 0;
  $ENV{CHIFFON_WEB_NAVIGATOR_DEBUG} = 1;
  $ENV{CHIFFON_WEB_RECIPE_DEBUG} = 0;
  $ENV{CHIFFON_WEB_SYSTEM_DEBUG} = 0;
};

use Mojo::ByteStream qw(b);

use JSON::XS qw(encode_json decode_json);
use Crypt::SaltedHash;
use Path::Class qw(file dir);
use XML::Simple;
use Time::HiRes;
use POSIX qw(strftime);

use constant DEBUG => $ENV{CHIFFON_WEB_DEBUG} || 0;

has xml => sub { XML::Simple->new };
has json => sub { JSON::XS->new };

# This method will run once at server start
sub startup {
  my $self = shift;

  chdir $self->home->detect;# startupの$selfはコントローラーではなくアプリが入っている
  warn qq{-- chdir @{[$self->home->detect]} } if DEBUG;

  $self->secret(b(file(__FILE__)->absolute)->sha1_sum);

  # name
  $self->helper(brandname => sub { q{Chiffon Viewer} });

  # Plugins
  $self->plugin('config');
  $self->plugin('I18N',
    namespace => 'Chiffon::Web::I18N',
    default => 'ja',
  );

  # Log
  $self->log->level($self->config->{log_level});

  # Static
  unshift @{$self->static->paths}, $self->config->{recipes_dir};

  # helpers
  # ユーザー情報を取得する
  $self->helper(
    get_user => sub {
      my $self = shift;
      my $user_id = shift || $self->session('user_id');
      return unless defined $user_id;
      my $config = $self->config;
      my $users = decode_json(file($config->{userfile})->slurp);
      my $user = +{
        name => $user_id,
        %{$users->{$user_id}}
      };
      return $user;
    }
  );

  # time_for_navigate
  $self->helper(
    time_for_navigate => sub {
      my $self = shift;
      my ($sec, $usec) = Time::HiRes::gettimeofday;
      my $time_for_navigate = {
        sec => $sec,
        usec => sprintf('%06d', $usec),
      };
      warn qq{-- time_for_navigate : @{[%{$time_for_navigate}]} } if DEBUG;
      return $time_for_navigate;
    }
  );

  # デバッグ出力用
  $self->helper(
    pretty_dumper => sub {
      my $self = shift;
      my $arg  = shift;
      my $json = $self->app->json;
      return $json->pretty->allow_nonref->allow_blessed(1)->convert_blessed(1)->encode($arg);
    }
  );

  # 閲覧ID生成
  $self->helper(
    session_id => sub {
      my $self = shift;
      my $session_id = $self->session('session_id');
      return $session_id if defined $session_id;
      my $user_name = $self->user_name;
      my ($sec, $usec) = Time::HiRes::gettimeofday;
      $usec = sprintf '%06d', $usec;
      my $datetime = strftime($self->config->{datetime_format}, localtime($sec));
      $session_id = qq{$user_name-$datetime.$usec};
      warn qq{-- session_id : $session_id } if DEBUG;
      $self->session(session_id => $session_id);
      return $session_id;
    }
  );

  # user_name
  $self->helper(
    user_name => sub {
      my $self = shift;
      my $user = $self->get_user;
      my $user_name = $user->{name};
      warn qq{-- user_name : $user_name } if DEBUG;
      return $user_name;
    }
  );

  # recipe_xml_file
  $self->helper(
    recipe_xml_file => sub {
      my $self = shift;
      my $recipe_xml_file = $self->session('recipe_xml_file');
      if (defined $recipe_xml_file) {
        return file($recipe_xml_file);
      }
      my $name = shift || '';
      return unless $name;
      my $config = $self->config;
      my $recipe_basename = $config->{recipe_basename};
      $recipe_xml_file = file($config->{recipes_dir}, $name, $recipe_basename);
      $self->session(recipe_xml_file => $recipe_xml_file->stringify);
      return $recipe_xml_file;
    }
  );

  # post_to_navigator
  $self->helper(
    post_to_navigator => sub {
      my $self = shift;
      my $args = shift // +{};
      my $data = {
        session_id => $self->session_id,
        user_name => $self->user_name,
        situation => undef,
        operation_contents => undef,
        time => $self->time_for_navigate,
        log_level => uc $self->app->log->level,
        %{$args}
      };
      warn qq{-- data : @{[encode_json($data)]} } if DEBUG;
      my $tx = $self->ua->post($self->config->{navigator_endpoint}, json => $data);
      return $tx->res;
    }
  );

  # Navigator通信用
  # 閲覧IDリセット
  $self->helper(
    clear_recipe_session => sub {
      my $self = shift;
      $self->session('session_id' => undef);
      $self->session('recipe_xml_file' => undef);
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
  $r->via(qw(get post))->route(qq{/:controller/:action/:id})
    ->to(controller => 'index', action => 'start', id => '');
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
