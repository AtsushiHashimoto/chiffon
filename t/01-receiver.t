use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Chiffon::Web');

$t->get_ok('/receiver')->status_is(500);

$t->get_ok('/receiver?sessionid=test_session&string=test_message')
  ->status_is(200)->json_has('/status');

$t->post_ok('/login' => form => {user_id => 'test', pw => 'test'})
  ->status_is(302);

$t->websocket_ok('/external')->send_ok({json => {session_id => "test"}})
  ->message_ok->json_message_has('/status')->finish_ok;

done_testing();
