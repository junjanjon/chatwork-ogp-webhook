
# chatwork-ogp-webhook

チャットワークで URL のプレビューを実現する。

webhook と名前を付けましたが現在のこのリポジトリは webhook 機能がありません。

## 使い方

```shell
export CHATWORK_TOKEN=xxxx
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec ruby bot.rb
```

指定した `CHATWORK_TOKEN` のユーザーで、参加しているチャットに未読のURLが含まれるメッセージがあれば OGP 情報が投稿される。

bot ユーザで cron などで定期実行することを想定しています。
