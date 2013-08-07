package Chiffon::Web::Recipe;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_RECIPE_DEBUG} || 0;

use Path::Class qw(file dir);


# URL : /recipe
sub start {
  my $self = shift;
  my $logger = $self->app->log;

  my $config = $self->config;
  my $name = $self->param('name');

  my $recipe_xml_file = $self->recipe_xml_file($name);
  unless ($recipe_xml_file and -f $recipe_xml_file) {
    $logger->error(qq{file not found $recipe_xml_file});
    return $self->render_not_found;
  }
  unless (-r $recipe_xml_file) {
    $logger->error(qq{permission denied $recipe_xml_file});
    return $self->render(status => 403, data => '');
  }
  my $recipe_dir  = $recipe_xml_file->dir;
  warn qq{-- recipe_xml_file : $recipe_xml_file} if DEBUG;
  my $xml = $self->app->xml;
  my $recipe = $xml->XMLin($recipe_xml_file->stringify,
    keyattr => [],# 属性名を省略しない
    forceArray => 1,# 複数要素でなくても配列のリファレンスにする
    SuppressEmpty => '',# 空の要素を空文字列にする
  );

  unless (defined $recipe) {
    $logger->error(qq{parse error $recipe_xml_file});
    return $self->render_exception;
  }

  $self->stash(
    recipe => $recipe,
    name => $name,
  );

  $self->render(
    layout => 'default',
    title => $recipe->{title},
    template => 'recipe/start',
  );
}

1;
