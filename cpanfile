requires 'perl' => '5.012';
requires 'Mojolicious' => '4.16';
requires 'Path::Class' => 0;
requires 'Crypt::SaltedHash' => 0;
requires 'App::Rad' => 0;
requires 'Term::Encoding' => 0;
requires 'Term::ReadKey' => 0;



on 'test' => sub {
    requires 'Test::More', '0.98';
};

