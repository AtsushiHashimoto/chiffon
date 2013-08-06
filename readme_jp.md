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

以下のコマンドでテストサーバーが起動します。

    $ morbo script/chiffon_web

標準で``http://localhost:3000``でサーバーが起動します。

``Server available at http://127.0.0.1:3000.``という表示が出れば、ブラウザでアクセスするとログイン画面になります。

ユーザーが追加してあれば、そのユーザー名とパスワードでログインできます。

## ユーザー追加

以下のコマンドでユーザーを追加できます。

    $ ./script/user.pl add

コマンドを実行すると、ユーザー名、パスワード、パスワード確認、の順に入力待ちをしますので、適切に入力してください。

パスワードは4文字以上、半角英数記号（スペース、タブを除く）を受け付けるようにしています。

現在のところ、スクリプトからの削除はできません。ファイル（初期状態で``var/userfile``）を開き、直接編集・削除してください。

## 設定ファイル

clone した状態では設定ファイルはありません。

設定ファイルのひな形として「chiffon-web.conf.example」を用意していますので、「chiffon-web.conf」にリネームして使用してください。

各種ファイルのPATHは、このファイルからの相対パスで書きます。
