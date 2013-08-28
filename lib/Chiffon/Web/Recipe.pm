package Chiffon::Web::Recipe;
use Mojo::Base 'Mojolicious::Controller';

use constant DEBUG => $ENV{CHIFFON_WEB_RECIPE_DEBUG} || 0;

use Path::Class qw(file dir);
use Mojo::DOM;


# URL : /recipe
sub start {
  my $self   = shift;
  my $logger = $self->app->log;

  my $config = $self->config;
  my $name = $self->param('name') // '';
  if ($name eq '') {
    $logger->error(qq{missing recipe name});
    return $self->render_not_found;
  }

  # file exists check
  my $recipe_xml_file = $self->recipe_xml_file($name);
  unless ($recipe_xml_file and -f $recipe_xml_file) {
    $logger->error(qq{file not found $recipe_xml_file});
    return $self->render_not_found;
  }

  # file readable check
  unless (-r $recipe_xml_file) {
    $logger->error(qq{permission denied $recipe_xml_file});
    return $self->render(status => 403, data => '');
  }

  # validate
  (undef, my $err) = $self->hmml_validate($recipe_xml_file);
  if ($err) {
    return $self->render_exception(
      qq{invalid hmml document `$recipe_xml_file` : $err});
  }

  # id complement
  # optionalなidを含む要素を定義
  my @complement_targets = qw(
    object
    object_group
    video
    audio
    step
    substep
    notification
  );

  my $content = file($recipe_xml_file)->slurp;
  my $dom     = Mojo::DOM->new($content);
  my %ids;
  for my $element_name (@complement_targets) {
    $dom->find($element_name)->each(
      sub {
        my $elm = shift;
        return if exists $elm->{id};
        my $id;
        while (1) {
          $id = sprintf qq{$element_name%03d}, ++$ids{-counter}{$element_name};
          last unless $ids{$id}++;
        }
        $elm->{id} = $id;
        say $elm->{id};
      }
    );
  }

  my $complement_recipe_file = file($config->{complement_recipes_dir},
    $self->session_id, $config->{recipe_basename});
  $complement_recipe_file->dir->mkpath;
  $complement_recipe_file->spew($dom->to_xml);

  warn qq{-- recipe_xml_file : $complement_recipe_file } if DEBUG;
  my $recipe = $self->app->xml->XMLin(
    $complement_recipe_file->stringify,

    # 属性名を省略しない
    keyattr => [],

    # 複数要素でなくても配列のリファレンスにする
    forceArray => 1,

    # 空の要素を空文字列にする
    SuppressEmpty => '',
  );

  # parse check
  unless (defined $recipe) {
    return $self->render_exception(qq{parse error $complement_recipe_file});
  }

  # update recipe_xml_file
  $self->session(recipe_xml_file => $complement_recipe_file->stringify);

  # overview check
  my $overview = file($config->{recipes_dir}, $name, $recipe->{overview})->cleanup;
  unless ($overview and -f $overview) {
    return $self->render_exception(qq{overview not found $overview});
  }

  $self->stash(recipe => $recipe, name => $name,);

  $self->render(
    layout   => 'default',
    title    => $recipe->{title},
    template => 'recipe/start',
  );
}

1;
