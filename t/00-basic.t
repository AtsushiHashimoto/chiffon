use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Chiffon::Web');
$t->get_ok('/')->status_is(302);

$t->get_ok('/login')->status_is(200)->content_like(qr/Chiffon Viewer/);

done_testing();
