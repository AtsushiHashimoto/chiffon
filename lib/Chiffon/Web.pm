package Chiffon::Web;
use Mojo::Base 'Mojolicious';

our $VERSION = '0.13';

use Mojo::ByteStream qw(b);

use JSON::XS qw(encode_json decode_json);
use Crypt::SaltedHash;
use Path::Class qw(file dir);
use XML::LibXML;
use Time::HiRes;
use POSIX qw(strftime);
use Time::Piece;
use Try::Tiny;
use Capture::Tiny qw(capture);


use constant DEBUG => $ENV{CHIFFON_WEB_DEBUG} || 0;

has json       => sub { JSON::XS->new };
has ws_clients => sub { +{} };

sub startup {
  my $app = shift;

  chdir $app->home->detect;
  warn qq{-- chdir : @{[$app->home->detect]} } if DEBUG;

  $app->secret(b(file(__FILE__)->absolute)->sha1_sum);

  if ($app->mode eq 'production') {
    warn qq{-- production_mode\n} if DEBUG;

# Sessionをsecureに（httpsでログイン）する場合は，1を設定する
    $app->app->sessions->secure(0);
  }
  elsif ($app->mode eq 'development') {
    warn qq{-- development_mode\n} if DEBUG;

    # Sessionをsecureにする場合は，1を設定する
    $app->app->sessions->secure(0);
  }


  # name
  $app->helper(brandname => sub {q{Chiffon Viewer}});

  # Plugins
  $app->plugin(
    'Config' => {
      default => {
        hypnotoad => {listen => ['http://*:8080'], workers => 2, proxy => 1},
        userfile               => 'var/userfile',
        recipe_basename        => 'recipe.xml',
        recipes_dir            => 'var/recipes',
        navigator_endpoint     => 'http://localhost:4567/navi/default',
        relax_ng_file          => 'rng/hmml-basic.rng',
        log_level              => 'info',
        datetime_format        => '%Y.%m.%d_%H.%M.%S',
        notification_live_sec  => 5,
        update_sound           => '',
        video_width            => 320,
        video_height           => 180,
        complement_recipes_dir => 'var/complement_recipes',
      },
      file => 'chiffon-web.conf',
    }
  );
  $app->plugin('I18N', namespace => 'Chiffon::Web::I18N', default => 'ja');

  # Config check
  my $datetime_format = $app->config->{datetime_format};
  my $check           = Time::Piece->new->strftime($datetime_format);
  die 'invalid character in datetime_format. You use `-` or `.` or `_`'
    unless $check =~ /\A[-\.\_\w]+\z/ms;

  # Log
  $app->log->level(lc $app->config->{log_level});

  # Sessions
  $app->sessions->cookie_path('/')->default_expiration(3600);

  # ログの発生場所を追加で書き込む
  no warnings 'redefine';
  *Mojo::Log::format = sub {
    my ($self, $level, @lines) = @_;

# 4つ前がログの書き込み指定を行なっている（Mojolicious 3.44）
    my @caller = caller(4);
    my $caller = join ' ', $caller[0], $caller[2];
    my ($sec, $usec) = Time::HiRes::gettimeofday;
    $usec = sprintf '%06d', $usec;
    my $datetime = join '.',
      Time::Piece->new($sec)->strftime($datetime_format), $usec;
    my $LEVEL = uc $level;
    return qq{[$datetime] [$LEVEL] [$caller] } . join("\n", @lines) . "\n";
  };

  # Static
  unshift @{$app->static->paths}, $app->config->{recipes_dir};

  # helpers
  # ユーザー情報を取得する
  $app->helper(
    get_user => sub {
      my $self = shift;
      my $user_id = shift || $self->session('user_id') // '';
      return if $user_id eq '';
      my $config = $self->config;
      my $users  = decode_json(file($config->{userfile})->slurp);
      my $user   = +{name => $user_id, %{$users->{$user_id}}};
      return $user;
    }
  );

  # time_for_navigate
  $app->helper(
    time_for_navigate => sub {
      my $self = shift;
      my ($sec, $usec) = Time::HiRes::gettimeofday;
      my $time_for_navigate = {sec => $sec, usec => sprintf('%06d', $usec),};
      warn qq{-- time_for_navigate : @{[%{$time_for_navigate}]} } if DEBUG;
      return $time_for_navigate;
    }
  );

  # デバッグ出力用
  $app->helper(
    pretty_dumper => sub {
      my $self = shift;
      my $arg  = shift;
      my $json = $self->app->json;
      return $json->pretty->allow_nonref->allow_blessed(1)->convert_blessed(1)
        ->encode($arg);
    }
  );

  # 閲覧ID生成
  $app->helper(
    session_id => sub {
      my $self       = shift;
      my $session_id = $self->session('session_id');
      return $session_id if defined $session_id;
      my $user_name = $self->user_name;
      my ($sec, $usec) = Time::HiRes::gettimeofday;
      $usec = sprintf '%06d', $usec;
      my $datetime
        = strftime($self->config->{datetime_format}, localtime($sec));
      $session_id = qq{$user_name-$datetime.$usec};
      warn qq{-- create session_id : $session_id } if DEBUG;
      $self->session(session_id => $session_id);
      return $session_id;
    }
  );

  # user_name
  $app->helper(
    user_name => sub {
      my $self      = shift;
      my $user      = $self->get_user;
      my $user_name = $user->{name};
      warn qq{-- user_name : $user_name } if DEBUG;
      return $user_name;
    }
  );

  # recipe_xml_file
  $app->helper(
    recipe_xml_file => sub {
      my $self = shift;
      my $recipe_xml_file = $self->session('recipe_xml_file') // '';
      if ($recipe_xml_file ne '') {
        return file($recipe_xml_file);
      }
      my $name = shift || '';
      if ($name eq '') {
        die 'recipe name required';
      }
      my $config          = $self->config;
      my $recipe_basename = $config->{recipe_basename};
      $recipe_xml_file = file($config->{recipes_dir}, $name, $recipe_basename);
      $self->session(recipe_xml_file => $recipe_xml_file->stringify);
      return $recipe_xml_file;
    }
  );

  # validate
  $app->helper(
    hmml_validate => sub {
      my $self      = shift;
      my $hmml_file = shift or die 'recipe file required';
      my $config    = $self->config;
      my $hmml_doc  = XML::LibXML->new->parse_file($hmml_file);
      my $rngschema = XML::LibXML::RelaxNG->new(
        location => file($config->{relax_ng_file})->stringify);
      my $err;
      my ($stdout, $stderr) = capture {
        $rngschema->validate($hmml_doc);
      };
      warn qq{-- result : @{[$stdout, $stderr]} } if DEBUG;
      return $stdout, $stderr;
    }
  );


  # post_to_navigator
  $app->helper(
    post_to_navigator => sub {
      my $self = shift;
      my $args = shift // +{};
      my $data = {
        session_id         => $self->session_id,
        user_name          => $self->user_name,
        situation          => undef,
        operation_contents => undef,
        time               => $self->time_for_navigate,
        log_level          => uc $self->app->log->level,
        %{$args}
      };
      warn qq{-- data : @{[encode_json($data)]} } if DEBUG;
      my $tx
        = $self->ua->post($self->config->{navigator_endpoint}, json => $data);
      if (my $res = $tx->success) {
        return decode_json($res->body);
      }
      else {
        $self->app->log->error($tx->error);

# 「Connection refused」をJSONで渡すと「61」になるのは何故だ！
# return +{status => scalar $tx->error};
        return +{status => 'Error : ' . $tx->error};
      }
    }
  );

  # Navigator通信用
  # 閲覧IDリセット
  $app->helper(
    clear_recipe_session => sub {
      my $self = shift;
      warn qq{-- clear_recipe_session } if DEBUG;
      $self->session('session_id'      => undef);
      $self->session('recipe_xml_file' => undef);
      return;
    }
  );

  # validate hash
  $app->helper(
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
  $app->helper(
    add_stash_message => sub {
      my ($self, $msg) = @_;
      my $messages = $self->stash('message') // [];
      push @{$messages}, $msg;
      $self->stash(message => $messages);
    }
  );
  $app->helper(
    stash2flash => sub {
      my ($self) = @_;
      my $messages = $self->stash('message') // [];
      $self->stash(message => []);
      $self->flash(message => $messages);
    }
  );

  # メッセージをリセット
  $app->helper(
    reset_stash_message => sub {
      shift->stash(message => []);
    }
  );


  # Router
  my $r = $app->routes;

  # 認証なしでOKのルート
  # login
  $r->route('/login')->via(qw(get post))->to('system#login');
  $r->route('/receiver')->via(qw(get))->to('receiver#start');

  # 認証
  $r = $r->bridge->to('system#auth');

  # 認証が必要なルート
  # ログアウト
  $r->route('/logout')->to('system#logout');

  # メニュー
  $r->via(qw(get post))->route(qq{/:controller/:action/:id})
    ->to(controller => 'index', action => 'start', id => '');
  $r->websocket('/external')->to('external#start');
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

Nobutaka Wakabayashi

Atsushi Hashimoto

=cut
