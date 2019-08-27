# frozen_string_literal: true

require 'json'
require 'chatwork'
require_relative './message_parse'

CHATWORK_TOKEN = ENV.fetch('CHATWORK_TOKEN')
ChatWork.api_key = CHATWORK_TOKEN

def get_unread_rooms
  all_rooms = ChatWork::Room.get
  all_rooms.reject { |room| room.unread_num.zero? }
end

def get_me_account_id
  me = ChatWork::Me.get
  me.account_id
end

def read_room(room_id:)
  messages = ChatWork::Message.get(room_id: room_id, force: true)
  ChatWork::Message.read(room_id: room_id, message_id: messages.last.message_id)
rescue StandardError => e
  p "既読失敗したにゃ #{e} #{e.backtrace}"
end

def main
  p me_account_id = get_me_account_id
  p unread_rooms = get_unread_rooms

  unread_rooms.reject { |room| room.role == 'readonly' }.each do |room|
    messages = ChatWork::Message.get(room_id: room.room_id)

    if messages.nil?
      read_room(room_id: room.room_id)
      next
    end

    messages[-[messages.length, 3].min..-1].reject { |message| message.account.account_id == me_account_id }.each do |data|
      ogp_data = parse(data.body)
      next if ogp_data.nil?

      response = "#{ogp_data[:title]}[hr]#{ogp_data[:description]}"

      if ogp_data[:filename].nil?
        ChatWork::Message.create(room_id: room.room_id, body: response)
      else
        filepath = ogp_data[:filename]
        file = Faraday::UploadIO.new(filepath, 'multipart/mixed')
        ChatWork::File.create(room_id: room.room_id, file: file, message: response)
      end
    end

    read_room(room_id: room.room_id)
  end
end

main
