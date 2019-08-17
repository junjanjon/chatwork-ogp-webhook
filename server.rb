# frozen_string_literal: true

require 'json'
require 'webrick'
require_relative './message_parse'
require 'openssl'
require 'base64'
require 'chatwork_webhook_verify'

CHATWORK_TOKEN = ENV.fetch('CHATWORK_TOKEN')
WEBHOOK_TOKEN = ENV.fetch('WEBHOOK_TOKEN')

s = WEBrick::HTTPServer.new(
  Port: 18_080,
  HTTPVersion: WEBrick::HTTPVersion.new('1.1'),
  AccessLog: [[open(IO::NULL, 'w'), '']] # アクセスログを出力しない
)

def handling_request(req)
  puts req.raw_header
  return unless req.body

  puts verify = ChatworkWebhookVerify.verify?(token: WEBHOOK_TOKEN, body: req.body, signature: req['X-ChatWorkWebhookSignature'])
  return unless verify

  p body = JSON.parse(req.body)
  return if body['webhook_event_type'] != 'mention_to_me'

  room_id = body['webhook_event']['room_id']
  message = body['webhook_event']['body']

  ogp_data = parse(message)
  return if ogp_data.nil?

  p ogp_data
  puts response = "#{ogp_data[:title]}[hr]#{ogp_data[:description]}"

  token = CHATWORK_TOKEN
  if ogp_data[:filename].nil?
    `curl -v -X POST -H "X-ChatWorkToken: #{token}" -d 'body=#{response}&self_unread=1' "https://api.chatwork.com/v2/rooms/#{room_id}/messages"`
  else
    filepath = ogp_data[:filename]
    `curl -v -X POST -H "X-ChatWorkToken: #{token}" -F"file=@#{filepath}" -F'message=#{response}' "https://api.chatwork.com/v2/rooms/#{room_id}/files"`
  end
rescue StandardError => e
  warn e.backtrace.join("\n")
  warn 'なにか問題が発生しました。'
end

s.mount_proc('/') do |req, res|
  puts "========== #{Time.new} =========="
  # レスポンス内容を出力
  res.status = 200
  res['Content-Type'] = 'text/html'
  res.body = 'OK'

  # リクエスト内容を出力
  handling_request(req)
end

s.start
