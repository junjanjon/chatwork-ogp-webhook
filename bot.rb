require 'json'
require_relative './message_parse'


WATCH_ROOM_ID = ENV.fetch('WATCH_ROOM_ID')
CHATWORK_TOKEN = ENV.fetch('CHATWORK_TOKEN')

WATCH_ROOM_ID.split(',').each do |room_id|
	messages = %x(curl -X GET -H "X-ChatWorkToken: #{CHATWORK_TOKEN}" "https://api.chatwork.com/v2/rooms/#{room_id}/messages?force=0")

	next if messages.empty?

	p messages = JSON.parse(messages);

	messages.each do |data|
		ogp_data = parse(data["body"])
		next if ogp_data.nil?

		p ogp_data
		response = "#{ogp_data[:title]}[hr]#{ogp_data[:description]}"

		if ogp_data[:filename].nil?
			%x(curl -v -X POST -H "X-ChatWorkToken: #{CHATWORK_TOKEN}" -d 'body=#{response}&self_unread=1' "https://api.chatwork.com/v2/rooms/#{room_id}/messages")
		else
			filepath = ogp_data[:filename]
			%x(curl -v -X POST -H "X-ChatWorkToken: #{CHATWORK_TOKEN}" -F"file=@#{filepath}" -F'message=#{response}' "https://api.chatwork.com/v2/rooms/#{room_id}/files")
		end
		sleep(1)
	end
	sleep(1)
end