use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Path::Class qw(file dir);
use File::Temp ();

my $t = Test::Mojo->new('Chiffon::Web');

my $userfile = File::Temp->new;
file($userfile)
  ->spew(q!{"test":{"salted":"{SSHA}TmaNl3aFim19ZQbhqWwat3eZafyaysFo"}}!);
my $recipes_dir = File::Temp->newdir;
my $config      = $t->app->config;
$config->{userfile}    = $userfile;
$config->{recipes_dir} = $recipes_dir;

my $test_recipe
  = file($recipes_dir, 'test_recipe', $config->{recipe_basename});
my $test_recipe_content = file(file(__FILE__)->dir, 'recipe.xml')->slurp;
$test_recipe->dir->mkpath;
$test_recipe->spew($test_recipe_content);

$t->get_ok('/')->status_is(302);

$t->get_ok('/login')->status_is(200)->content_like(qr/Chiffon Viewer/);

$t->post_ok('/login' => form => {user_id => 'test', pw => 'test'})
  ->status_is(302)->or(sub { diag explain $t->tx->res->body })
  ;    # エラーだけを取得する方法はないかねぇ

$t->get_ok('/')->status_is(200)->text_like('div.alert' => qr/Welcome test/);

$t->get_ok('/recipe' => form => {name => 'test_recipe'})->status_is(200)
  ->text_like('h1' => qr/テスト用レシピ/)->or(sub {diag explain $t->tx->res->body});

$t->get_ok('/recipe')->status_is(404);
$t->get_ok('/system')->status_is(302);
$t->get_ok('/i18n')->status_is(404);

$t->get_ok('/navigator')->status_is(200);

# Navigator
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
$t->get_ok('/navigator/external')->status_is(500);


done_testing();

