use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Path::Class qw(file dir);
use File::Temp ();

$ENV{'MOJO_MODE'} = 'production';

my $t = Test::Mojo->new('Chiffon::Web');
my $body;

$body = $t->get_ok('/login')->status_is(200)->content_like(qr/Chiffon Viewer/)
  ->tx->res->body;
spew_html('var/login.html', $body);


$t->post_ok('/login' => form => {user_id => 'test', pw => 'test'})
  ->status_is(302)->or(sub { diag explain $t->tx->res->body })
  ;    # エラーだけを取得する方法はないかねぇ

$body = $t->get_ok('/')->status_is(200)->text_like('div.alert' => qr/Welcome test/)
  ->tx->res->body;
spew_html('var/index.html', $body);

$body = $t->get_ok('/recipe' => form => {name => 'test_recipe'})->status_is(200)
  ->text_like('h1' => qr/テスト用レシピ/)
  ->tx->res->body;
spew_html('var/test_recipe.html', $body);

done_testing();

sub spew_html {
  my $filename = shift;
  my $body = shift;
  $body =~ s|="/(?!/)|="./|msg;
  file($filename)->spew($body);
}
