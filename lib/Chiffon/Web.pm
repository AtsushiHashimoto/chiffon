package Chiffon::Web;
use Mojo::Base 'Mojolicious';

our $VERSION = "0.01";


# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
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

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

* Nobutaka Wakabayashi
* Atsushi Hashimoto

=cut
