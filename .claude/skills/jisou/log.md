# 自走ログ

回ごとの経過は書かない（PR は git 履歴で追える）。200 行以内に保つ。

## もう出さない候補

## 測って分かった前提

- RunSpecs は 1 分ほどで終わる
- 本番 DB は Fly ボリューム上の SQLite で、マイグレーションはマシン起動時の `db:prepare` で流れる。デプロイが失敗するとマイグレーションだけ流れた状態にはならないが、戻すにはボリュームの復元が要る

## 踏んだ罠

- `.ruby-version` の Ruby が入っていないことがある。`rbenv install` で入れて `/opt/rbenv/versions/<版>/bin` を PATH の先頭に置く
- system spec は `/opt/node22/bin` の古い chromedriver を拾うと Chrome と版が合わず落ちる。PATH から外すと Selenium Manager が合う版を取ってくる
- `spec/system/sessions_spec.rb` の「email が違うとき」はローカルでときどき落ちる（flaky）
- rspec を流すと `app/assets/builds` が消えることがある。開発サーバーで画面を見る前に `bin/rails dartsass:build` する
- PR 本文に `Closes` を2つ並べると片方しか閉じないことがある。マージ後に issue の状態を確かめる

## 残っている候補

- 本番の `config.action_mailer.default_url_options` の host が `example.com` のままで、メール内のリンクが開けない（本番ドメインは #21 待ち）
- 通常ログイン（`SessionsController`）に `reset_session` が無い（セッション固定の対策）
- 終了済みイベントでも参加をキャンセルできる。許すかどうか未定
- main の CodeQL（Analyze (javascript)）が失敗している。RunSpecs ではないので未対応
