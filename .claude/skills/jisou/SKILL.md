---
name: jisou
description: beerkeeper を自走で1回まわす手順。定期実行や「自走で」「なんかやろう」と言われたときに読む。release マイルストーンの issue を priority 順に実装・マージし、終わったら log.md を更新する
---

# 自走で1回まわす

北極星は `release` マイルストーン（mitaka.rb の定例会を beerkeeper だけで回せる状態）。マイルストーンの issue が全部閉じるまでは、それ以外に手を広げない。

リリース前か後かは CLAUDE.md の「Release state」の行で決まる。自分では書き換えない。

## 手順

1. `git switch main && git pull` で main を最新にする。前回から残っている自分の open な PR があれば、新しく始める前に片付ける（CI が緑ならマージ、赤なら直す）
2. [log.md](log.md) を読む
3. main の RunSpecs が赤なら、それを最優先で直す。`ruby head test` は Ruby の開発版の問題なので対象にしない
4. 実装する issue を最大3本選ぶ
   - `release` マイルストーンの open な issue を `priority: high` → `medium` → `low` の順、同じ priority なら番号の小さい順に見る
   - `owner` ラベルの issue と、本文の「依存」にある issue がまだ open のものは飛ばす
   - 受け入れ条件が書かれていない issue は、実装する前に pdm スキルのモード1で仕様化する
   - マイルストーンに実装できる issue が無ければ、pdm スキルのモード3で `release` に足りないものを探し、起票して報告する（その回は実装しない）
5. 1 issue 1 PR で実装する
   - ブランチを切り、テストから書く（t_wada の TDD）。コミットは意味単位で分け、`git add -A` は使わずパスを指定する。force push しない
   - PR 本文は「何をしたか」を短い日本語で書き、`Closes #<n>` を付ける
   - マージ前に `beerkeeper-invariants-reviewer` agent に差分を見せる。指摘があれば直す
   - CI（test と lint）が緑なら自分でマージする（squash）。main へのマージで本番に自動デプロイされる
   - 同じ PR で CI を2回直しても緑にならなければ、閉じずに残して報告する
6. 終わったら log.md を更新する PR を出してマージし、最後のメッセージに回の結果を短く書く（マージした PR、残した PR と理由、候補として残したもの、置いた仮定）。最後のメッセージはオーナーに通知で届く

## 実装しないもの（候補として報告に残す）

- `release` マイルストーンの範囲や北極星を変えること（issue をマイルストーンから外す・足すのも含む。足したいものは起票して報告する）
- 外部サービスの登録・課金が要るもの。必要なシークレットの名前と手順を `owner` の issue に書き足すところまではやる
- 他人の名義での投稿・送信。upstream（`mitakarb/beerkeeper`）への操作すべて
- リリース後のみ: 本番に流れるマイグレーション、シークレットの変更、データの削除や書き換え。PR を出すところで止めて報告する

## 環境の癖

- クラウドのセッションでは `gh` の GraphQL が 403 になることがある。そのときは PR の作成・マージ・CI の確認を `gh api`（REST: `repos/dlwr/beerkeeper/pulls`、`.../pulls/<n>/merge` に `-X PUT -f merge_method=squash`、`.../commits/<sha>/check-runs`）で行う
- `gh` はフォーク元を既定にしがちなので、必ず `-R dlwr/beerkeeper` を付ける
- system spec に Chrome が要る。環境に無ければ system spec はローカルで流せなかったと書き、CI の結果で判断する
