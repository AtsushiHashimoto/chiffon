#!/usr/bin/env perl
use utf8;
use Mojo::Base -strict;
use Path::Class qw(file dir);
use JSON::XS qw(encode_json decode_json);
use FindBin;
use lib qq{$FindBin::Bin/../lib};
use Mojo::Log;
use Crypt::SaltedHash;
use App::Rad;

use Term::Encoding qw(term_encoding);
my $encoding = term_encoding;

binmode STDOUT => ":encoding($encoding)";
binmode STDIN  => ":encoding($encoding)";
binmode STDERR => ":encoding($encoding)";

use Term::ReadKey;

our $logger   = Mojo::Log->new();
our $base_dir = file(__FILE__)->dir->parent->resolve;
my $config_file = file($base_dir, 'chiffon-web.conf');
our $config = require $config_file;
our $pw_file = file($base_dir, $config->{userfile});

App::Rad->run;

sub setup {
  my $c = shift;
  $c->register_commands({add => 'ユーザーを作成します',});
}

# init
sub add {
  my $c = shift;

  ReadMode 'normal';
  print 'Username : ';
  chomp(my $name = <STDIN>);
  unless (validate_name($name)) {
    return 'Usernameが正しくありません';
  }

  ReadMode 'noecho';
  print 'Password : ';
  chomp(my $pw = <STDIN>);
  print "\n";
  print 'Retype Password : ';
  chomp(my $r_pw = <STDIN>);
  print "\n";
  ReadMode 'normal';

  unless ($pw eq $r_pw) {
    return 'Retype Passwordが正しくありません';
  }
  unless (validate_pw($pw)) {
    return 'Passwordが正しくありません';
  }

  # 記録する
  my $users;
  $users = decode_json($pw_file->slurp) if -f $pw_file;
  if (defined $users and $users->{$name}) {
    return
      join('', 'ユーザー「', $name, '」は既に存在しています');
  }
  my $csh = plain2csh($pw);
  $users->{$name} = +{salted => $csh};
  $pw_file->spew(encode_json($users));

  return join('', 'ユーザー「', $name, '」を追加しました');
}

# 名前の正当性を確認する
sub validate_name {
  my $name = shift;
  return if length $name < 3;   # 3文字未満なら拒否
  return if $name =~ m!\W!ms;   # 半角英数とアンダーバーのみ有効
  return 1;
}

# パスワードの正当性を確認する
sub validate_pw {
  my $pw = shift;
  return if length $pw < 4;     # 4文字未満なら拒否
  return
    if $pw =~ m!\s!ms
    ; # 空白相当文字（スペース、改行、タブ）が含まれていたら拒否
  return 1;
}

# 暗号化
sub plain2csh {
  my ($plain) = @_;
  my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
  $csh->add($plain);
  return $csh->generate;
}

