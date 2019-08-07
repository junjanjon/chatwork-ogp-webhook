require 'faraday'
require 'open_graph_reader'
require 'uri'

def get_url_expander(url)
	url_expander = %x(curl -I -s "#{url}" | grep -i Location | cut -d ' ' -f 2)
	return url if url_expander.length == 0
	url_expander.chomp
end

def ogp_parse(url)
	p url = get_url_expander(url)
	p object = OpenGraphReader.fetch(url)

	return {
		title: 'OpenGraphReader 失敗',
		description: '',
	} if object.nil?

	p data = {
		title: object.og.title.gsub(/'/, ''),
		image_url: object.og.image.url,
		description: object.og.description.gsub(/'/, ''),
	}

	return data
end

def get_url(message)
	match_result = message.match(/(http[^ \s\r\n\[]*)/)
	return nil if match_result.nil?
	match_result[1]
end

def download_image_file(image_url)
	response = Faraday.get(image_url)
	filename = "OGP_" + image_url.split('/').last.chomp(':large').split('?')[0]
	File.write(filename, response.body)
	return filename
end

def parse(message)
	p message

	# p match_result = message.match(/ogp/)
	# return nil if match_result.nil?
	
	url = get_url(message)
	return nil if url.nil?
	ogp_data = ogp_parse(url)
	return nil if ogp_data.nil?

	unless ogp_data[:image_url].nil?
		filename = download_image_file(ogp_data[:image_url])
		ogp_data[:filename] = filename
	end

	return ogp_data
rescue => error
	p "失敗したにゃ #{error}"
	return nil
end



if __FILE__ == $0
	# p parse("https://supersalariedman.blogspot.com/2018/11/blog-post_74.html")
	# p parse('https://twitter.com/LoveLive_staff/status/1156374027180658690')
	p parse('https://www.thanko.jp/shopdetail/000000003314/')
	p parse('https://note.mu/rangatarou/n/n6541adc4c855')
	# parse('http://www.kenoh.com/2019/06/25_emaki.html?fbclid=IwAR0-8-Acz5x9tEtnj-gxNa_50YLWyxc9T_N5rC7rUXhPi-ou-tBatvHbg3U
 # ogp')

	# parse('https://ift.tt/2X2Khle ogp')
	# parse('ogp https://www.bbc.com/japanese/48767764')
	# parse('http://ogp.me について教えて')
	# parse('https://ref.xaio.jp/ruby/classes/string/split について教えて ogp')
	# parse('https://mail.google.com/mail/u/0/#inbox')
	# parse('https://gamebiz.jp/?p=241852 ogp')
	# parse('https://qiita.com/akicho8/items/efe59578f12d6b7f5626 ogp')
end
