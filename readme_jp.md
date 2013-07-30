# インストール

## git

http://git-scm.com/

こちらからダウンロードして、インストールしておきます。

## Perl

ユーザー領域にPerlを構築するのがオススメです。

ユーザーのホームディレクトリに``.plenv``というディレクトリを作ってそこで管理します。

Perlを管理するツール（plenv）と、Perl本体、パッケージ管理ツール（cpanminus）をインストールします。

    $ git clone git://github.com/tokuhirom/plenv.git ~/.plenv
    $ echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile
    $ echo 'eval "$(plenv init -)"' >> ~/.bash_profile
    $ exec $SHELL -l
    $ git clone git://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
    $ plenv install 5.16.3
    $ plenv rehash
    $ plenv global 5.16.3
    $ plenv install-cpanm

``.bash_profile``は適宜読み替えてください。``.bashrc``だったり``.zshrc``だったりします。

## Chiffon-Viewer

上記のようにインストールした場合のインストール方法です。

システムのPerlを使う場合は、モジュールのインストール時にroot権限が必要になります。

    $ git clone https://github.com/AtsushiHashimoto/chiffon-viewer.git
    $ cd chiffon-viewer
    $ git checkout develop
    $ cpanm --installdeps .

## 起動

    $ morbo script/chiffon_web

