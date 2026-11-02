# README

![Beerkeeper](app/assets/images/logo.svg)

mitaka.rb で作っているイベント管理アプリです :beers:

## Contributing

We welcome contributions! Please feel free to submit a Pull Request.

# 環境構築

- Ruby: 3.4.7
- Rails: 8.1.1
- DB: SQLite (development/test), Turso (production)

## Use Docker

```shell
# beerkeeperのDocker環境を過去に作ったことがあり、まっさらにしたい時
$ docker compose down --volumes

# まっさらな状態からやるとき
$ git clone git@github.com:mitakarb/beerkeeper.git
$ cd beerkeeper
$ docker compose build
$ docker compose run --rm web bin/setup
$ docker compose up
# http://localhost:3000/ を確認

# Webサーバーの切り替え
## Puma (デフォルト)
$ docker compose up

## Falcon
$ WEB_SERVER=falcon docker compose up

# test
## 初回のみ
$ docker compose run --rm -e RAILS_ENV=test web bin/rails db:test:prepare
## spec実行
$ docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
```

## local

```shell
$ git clone git@github.com:mitakarb/beerkeeper.git
$ cd beerkeeper
$ bin/setup
$ bin/dev
# http://localhost:3000/ を確認
```

### Webサーバーの切り替え

デフォルトはPumaですが、環境変数 `WEB_SERVER` でFalconに切り替えられます。

```shell
# Puma (デフォルト)
$ bin/dev

# Falcon
$ WEB_SERVER=falcon bin/dev
```

## 動作確認

http://localhost:3000/ を開いてイベント一覧が表示されたらOKです:)

## 本番 DB のバックアップと復元

本番の SQLite（`/rails/storage/production.sqlite3`）は Litestream で Tigris のバケットに継続レプリケーションしています。設定は `config/litestream.yml` です。

- Fly の secrets に `BUCKET_NAME`・`AWS_ACCESS_KEY_ID`・`AWS_SECRET_ACCESS_KEY`・`AWS_ENDPOINT_URL_S3`・`AWS_REGION` があると、`bin/docker-entrypoint` が `litestream replicate -exec` で Rails を起動します
- `BUCKET_NAME` が無いときは Litestream なしで起動します
- 起動時に DB ファイルが無く、レプリカがあれば、`db:prepare` の前にレプリカから復元します

### 空のボリュームへ復元する

```console
$ fly machine list -a beerkeeper-dlwr
$ fly machine destroy <machine_id> --force -a beerkeeper-dlwr
$ fly volumes create data --region nrt --size 1 -a beerkeeper-dlwr
$ fly deploy -a beerkeeper-dlwr
$ fly logs -a beerkeeper-dlwr   # "restore completed" を確認する
$ fly ssh console -a beerkeeper-dlwr -C "bin/rails runner 'p Event.count, User.count'"
```

壊れたボリュームは、復元を確かめてから `fly volumes destroy` で消します。

### 中身だけ確かめる

稼働中の DB に触れずに、レプリカを別ファイルへ復元できます。

```console
$ fly ssh console -a beerkeeper-dlwr -C "litestream restore -config /rails/config/litestream.yml -o /tmp/restored.sqlite3 /rails/storage/production.sqlite3"
```
