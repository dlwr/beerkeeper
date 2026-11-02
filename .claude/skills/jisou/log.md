# 自走ログ

回ごとの経過は書かない（PR は git 履歴で追える）。200 行以内に保つ。

## もう出さない候補

## 測って分かった前提

- RunSpecs は 1 分ほどで終わる
- 本番 DB は Fly ボリューム上の SQLite で、マイグレーションはマシン起動時の `db:prepare` で流れる。デプロイが失敗するとマイグレーションだけ流れた状態にはならないが、戻すにはボリュームの復元が要る

## 踏んだ罠

- クラウドの初期イメージには `.ruby-version` の Ruby が無く、`/opt/node22/bin` に Chrome と版の合わない chromedriver がある。環境の setup で `bin/cloud-setup` が片付ける。`ruby -v` が違えば `bash bin/cloud-setup` を流して `. /etc/profile.d/ruby.sh` する
- system spec の Chrome はパスワード漏えい検知のダイアログで次のテストの送信を止める。`spec/support/capybara.rb` で `profile.password_manager_leak_detection` を切ってある
- クラウドのセッションでは、ダウンロードした外部バイナリ（Litestream など）の実行が権限で拒否される。`strings` で中身を見るのと、チェックサムを確かめるところまではできる
- 1 つの作業ブランチで PR を続けて出すと、squash マージ済みの古いコミットがリモートに残って push が弾かれる。force push はせず、リモートのブランチをマージしてから push する
- rspec を流すと `app/assets/builds` が消えることがある。開発サーバーで画面を見る前に `bin/rails dartsass:build` する
- PR 本文に `Closes` を2つ並べると片方しか閉じないことがある。マージ後に issue の状態を確かめる

## 残っている候補

- 本番ログに image_processing gem が無いという警告が出る。variant を使っていなければ `config.active_storage.variant_processor = :disabled` で消える
- 通常ログイン（`SessionsController`）に `reset_session` が無い（セッション固定の対策）
- 終了済みイベントでも参加をキャンセルできる。許すかどうか未定
- 補欠: 編集で `max_size` を増やしても補欠は繰り上がらない（次のキャンセルまで空き枠と補欠が並ぶ）
- `Event#receive` は `RecordInvalid` も握りつぶすので、二重参加以外の検証エラーも「参加できませんでした」になる
- Litestream のコンテナは linux-x86_64 固定。arm64 の Mac で `docker compose build` すると使えないバイナリが入る（`BUCKET_NAME` が無ければ呼ばれない）
