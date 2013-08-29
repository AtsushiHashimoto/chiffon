requires 'perl'              => '5.012';
requires 'Mojolicious'       => '4.16';
recommends 'EV'              => 4;
recommends 'IO::Socket::IP'  => 0.16;
recommends 'IO::Socket::SSL' => 1.75;

requires 'Mojolicious::Plugin::I18N' => 0;
requires 'Path::Class'               => 0;
requires 'Crypt::SaltedHash'         => 0;
requires 'App::Rad'                  => 0;
requires 'Term::Encoding'            => 0;
requires 'Term::ReadKey'             => 0;
requires 'JSON::XS'                  => 0;
requires 'XML::LibXML'               => 0;

on develop => sub {
  requires 'Perl::Tidy', 0;
};
on test => sub {
  requires 'Test::More', '0.98';
};
