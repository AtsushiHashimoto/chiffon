use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Path::Class qw(file dir);

my $t = Test::Mojo->new('Chiffon::Web');
$t->get_ok('/')->status_is(302);

$t->get_ok('/login')->status_is(200)->content_like(qr/Chiffon Viewer/);

$t->post_ok('/login' => form => {
  user_id => 'test',
  pw =>'test',
})->status_is(302);

$t->get_ok('/')->status_is(200)->text_like('div.alert' => qr/Welcome test/);

my $body = $t->get_ok('/recipe' => form => {name => 'test_recipe'})->status_is(200)
  ->text_like('h1' => qr/テスト用レシピ/)
  ->tx->res->body;

file('var/text_recipe.html')->spew($body);

$t->get_ok('/navigator')->status_is(200);

$t->get_ok('/navigator/channel/guide')->status_is(200);
$t->get_ok('/navigator/channel/materials')->status_is(200);
$t->get_ok('/navigator/channel/overview')->status_is(200);
$t->get_ok('/navigator/navi_menu/test')->status_is(200);
$t->get_ok('/navigator/check/test')->status_is(200);

# エラー確認
$t->get_ok('/navigator/channel')->status_is(500);
$t->get_ok('/navigator/channel/hoge')->status_is(500);
$t->get_ok('/navigator/navi_menu')->status_is(500);
$t->get_ok('/navigator/check')->status_is(500);


done_testing();

