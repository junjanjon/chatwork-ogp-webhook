
# chatwork-ogp-webhook

チャットワークで URL のプレビューを実現する。

## 使い方

```shell
export CHATWORK_TOKEN=xxxx
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec ruby bot.rb
```

指定した `CHATWORK_TOKEN` のユーザーで、参加しているチャットに未読のURLが含まれるメッセージがあれば OGP 情報が投稿される。
