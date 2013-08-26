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

$t->get_ok('/receiver')->status_is(500);

$t->get_ok('/receiver?sessionid=test_session&string=test_message')
  ->status_is(200)->json_has('/status');

$t->post_ok('/login' => form => {user_id => 'test', pw => 'test'})
  ->status_is(302);

$t->websocket_ok('/external')->send_ok({json => {session_id => "test"}})
  ->message_ok->json_message_has('/status')->finish_ok;

done_testing();
