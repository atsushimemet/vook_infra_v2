# 既存のプログラムアップデート
sudo yum -y update

# ここでセキュリティ対策のためec2-userは削除しtestというユーザーを作成、パスワードも変更
# サーバにSSHログインできるよう、鍵の設定もしておく

# 環境構築に必要なパッケージをインストール
sudo yum  -y install git make gcc-c++ patch libyaml-devel libffi-devel libicu-devel zlib-devel readline-devel libxml2-devel libxslt-devel ImageMagick ImageMagick-devel openssl-devel libcurl libcurl-devel curl wget

# rbenv(rubyのバージョン管理ツール)をインストール、パスを通す
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source .bash_profile

# ruby-build(Rubyをバージョンごとにビルドするツール)のインストール
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv rehash

# rubyのインストール
rbenv install 3.2.2
rbenv global 3.2.2
rbenv rehash

# nvm(node.js管理ツール)のインストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
source ~/.bashrc

# nodeのインストール(偶数が安定版)
# ~nvm install 18.15.0~
# 最新のnodeがサポートできるglibcが搭載されていないので、nodeのバージョンを下げる
nvm install 16.20.0

# yarn(JSパッケージマネージャ)をインストール
npm install -g yarn

# MariaDBのアンインストール
yum list installed | grep mariadb
sudo yum remove mariadb-libs.x86_64

# MySQL8.0のリポジトリ追加(https://dev.mysql.com/downloads/repo/yum/で選択した)
sudo yum localinstall -y https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm

# MySQL8.0リポジトリの有効可
sudo yum-config-manager --disable mysql57-community
sudo yum-config-manager --enable mysql80-community

# クライアントツールのインストール
sudo yum install -y mysql-community-client mysql-devel