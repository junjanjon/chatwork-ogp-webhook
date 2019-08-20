# frozen_string_literal: true

require 'faraday'
require 'open-uri'
require 'nokogiri'
require 'uri'

def get_open_graph_data(url)
  if url.end_with?('.png') || url.end_with?('.jpg') || url.end_with?('.jpeg')
    return {
      title: '',
      image_url: url,
      description: ''
    }
  end

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

  data[:image_url] = doc.css('//meta[property="og:image"]/@content').first.to_s
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
  data = get_open_graph_data(url)

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

def ignore_hosts?(url)
  ignore_hosts = ENV.fetch('IGNORE_HOSTS') { 'localhost' }
  ignore_hosts = ignore_hosts.split(',')
  ignore_hosts.all? { |ignore_host| URI.parse(url).host.index(ignore_host).nil? }
end

def parse(message)
  p message

  url = get_url(message)
  return nil if url.nil?
  return nil unless ignore_hosts?(url)

  ogp_data = ogp_parse(url)
  return nil if ogp_data.nil?

  unless ogp_data[:image_url].nil? || ogp_data[:image_url].empty?
    filename = download_image_file(ogp_data[:image_url])
    ogp_data[:filename] = filename
    ogp_data[:title] = filename if ogp_data[:title].empty?
  end

  ogp_data
rescue StandardError => e
  p "失敗したにゃ #{e} #{e.backtrace}"
  nil
end

if $PROGRAM_NAME == __FILE__
  # p parse('https://twitter.com/LoveLive_staff/status/1156374027180658690').nil?
  # p parse('http://ogp.me について教えて').nil?
  # p parse('https://gamebiz.jp/?p=241852 ogp').nil?
end
