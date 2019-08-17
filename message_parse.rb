# frozen_string_literal: true

require 'faraday'
require 'open-uri'
require 'nokogiri'

def getOpenGraph(url)
  charset = nil
  html = open(url) do |f|
    charset = f.charset # 文字種別を取得
    f.read # htmlを読み込んで変数htmlに渡す
  end

  doc = Nokogiri::HTML.parse(html, charset)

  data = {}

  site_name_content = doc.css('//meta[property="og:site_name"]/@content')

  data[:title] = if site_name_content.empty?
                   doc.title.to_s
                 else
                   site_name_content.to_s
                 end

  description_content = doc.css('//meta[property="og:description"]/@content')
  data[:description] = if description_content.empty?
                         doc.css('//meta[name$="escription"]/@content').to_s
                       else
                         description_content.to_s
                       end

  data[:image_url] = doc.css('//meta[property="og:image"]/@content').to_s
  data
rescue StandardError => e
  p "失敗にゃ #{e}"
  nil
end

def get_url_expander(url)
  url_expander = `curl -I -s "#{url}" | grep -i Location | cut -d ' ' -f 2`
  return url if url_expander.empty?

  url_expander.chomp
end

def ogp_parse(url)
  p url = get_url_expander(url)
  data = getOpenGraph(url)

  if data.nil?
    return {
      title: 'OpenGraphReader 失敗',
      description: ''
    }
   end

  data = {
    title: data[:title].gsub(/'/, ''),
    image_url: data[:image_url],
    description: data[:description].gsub(/'/, '')
  }

  p data
end

def get_url(message)
  match_result = message.match(/(http[^ \s\r\n\[]*)/)
  return nil if match_result.nil?

  match_result[1]
end

def download_image_file(image_url)
  response = Faraday.get(image_url)
  filename = 'OGP_' + image_url.split('/').last.chomp(':large').split('?')[0]
  File.write(filename, response.body)
  filename
end

def parse(message)
  p message

  url = get_url(message)
  return nil if url.nil?

  ogp_data = ogp_parse(url)
  return nil if ogp_data.nil?

  unless ogp_data[:image_url].nil? or ogp_data[:image_url].empty?
    filename = download_image_file(ogp_data[:image_url])
    ogp_data[:filename] = filename
  end

  ogp_data
rescue StandardError => e
  p "失敗したにゃ #{e} #{e.backtrace}"
  nil
end

if $PROGRAM_NAME == __FILE__
  # p parse("https://supersalariedman.blogspot.com/2018/11/blog-post_74.html").nil?
  # p parse('https://twitter.com/LoveLive_staff/status/1156374027180658690').nil?
  # p parse('https://www.thanko.jp/shopdetail/000000003314/')
  # p parse('https://note.mu/rangatarou/n/n6541adc4c855').nil?
  # p parse('https://ift.tt/2X2Khle ogp').nil?
  # p parse('ogp https://www.bbc.com/japanese/48767764').nil?
  # p parse('http://ogp.me について教えて').nil?
  # p parse('https://ref.xaio.jp/ruby/classes/string/split について教えて ogp').nil?
  # p parse('https://www.toyomaru.jp/main/machine/sushizanmai_gokujyou/').nil?

  # p parse('https://gamebiz.jp/?p=241852 ogp').nil?
  # p parse('https://qiita.com/akicho8/items/efe59578f12d6b7f5626 ogp').nil?
end
