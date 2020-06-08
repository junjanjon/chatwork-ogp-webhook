# frozen_string_literal: true

require 'faraday'
require 'open-uri'
require 'nokogiri'
require 'uri'
require 'fileutils'

def get_open_graph_data(url)
  if url.end_with?('.png') || url.end_with?('.jpg') || url.end_with?('.jpeg')
    return {
      title: '',
      image_url: url,
      description: ''
    }
  end

  charset = nil
  html = open(url, "User-Agent" => "bot") do |f|
    charset = f.charset # 文字種別を取得
    f.read # htmlを読み込んで変数htmlに渡す
  end

  doc = Nokogiri::HTML.parse(html, charset)

  data = {}

  data[:title] = doc.title.to_s

  description_content = doc.css('//meta[property="og:description"]/@content')
  data[:description] = if description_content.empty?
                         doc.css('//meta[name$="escription"]/@content').to_s
                       else
                         description_content.to_s
                       end

  data[:image_url] = doc.css('//meta[property="og:image"]/@content').first.to_s
  data
rescue StandardError => e
  p "get_open_graph_data に失敗したにゃ #{e} #{e.backtrace}"
  nil
end

def get_url_expander(url)
  url_expander = `curl -I -s "#{url}" | grep -i Location | cut -d ' ' -f 2`
  url_expander = url_expander.chomp
  return url if url_expander.empty?
  return url_expander unless url_expander[0] == '/'

  url_generic = URI.parse(url)
  "#{url_generic.scheme}://#{url_generic.host}#{url_expander}"
end

# Rubyで画像ファイルの種別を判定 | 酒と涙とRubyとRailsと
# https://morizyun.github.io/ruby/tips-image-type-check-png-jpeg-gif.html
def image_type(file_path)
  File.open(file_path, 'rb') do |f|
    begin
      header = f.read(8)
      f.seek(-12, IO::SEEK_END)
      footer = f.read(12)
    rescue
      return nil
    end

    if header[0, 2].unpack('H*') == %w(ffd8) && footer[-2, 2].unpack('H*') == %w(ffd9)
      return 'jpg'
    elsif header[0, 3].unpack('A*') == %w(GIF) && footer[-1, 1].unpack('H*') == %w(3b)
      return 'gif'
    elsif header[0, 8].unpack('H*') == %w(89504e470d0a1a0a) && footer[-12,12].unpack('H*') == %w(0000000049454e44ae426082)
      return 'png'
    end
  end
  nil
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

  data
end

def get_url(message)
  message = message.gsub(/\[qt\].*\[\/qt\]/m, '')
  match_result = message.match(/(http[^ \s\r\n\[]*)/)
  return nil if match_result.nil?

  match_result[1]
end

def download_image_file(image_url)
  response = Faraday.get(image_url)
  filename = 'OGP_' + image_url.split('/').last.chomp(':large').split('?')[0]
  File.write(filename, response.body)
  extname = image_type(filename)
  return filename if extname.nil?
  final_filename = File.basename(filename, ".*") + '.' + extname
  return filename if filename == final_filename
  FileUtils.copy(filename, final_filename)
  final_filename
end

def ignore_hosts?(url)
  ignore_hosts = ENV.fetch('IGNORE_HOSTS') { 'localhost' }
  ignore_hosts = ignore_hosts.split(',')
  ignore_hosts.all? { |ignore_host| URI.parse(url).host.index(ignore_host).nil? }
end

def parse(message)
  message

  url = get_url(message)
  return nil if url.nil?
  return nil unless ignore_hosts?(url)

  ogp_data = ogp_parse(url)
  return nil if ogp_data.nil?

  begin
    unless ogp_data[:image_url].nil? || ogp_data[:image_url].empty?
      filename = download_image_file(ogp_data[:image_url])
      ogp_data[:filename] = filename
      ogp_data[:title] = filename if ogp_data[:title].empty?
    end
  rescue StandardError => e
    p "イメージのダウンロードに失敗したにゃ #{e} #{e.backtrace}"
  end

  ogp_data
rescue StandardError => e
  p "全体的に失敗したにゃ #{e} #{e.backtrace}"
  nil
end

if $PROGRAM_NAME == __FILE__
  p parse('https://www.pixiv.net/member_illust.php?mode=medium&illust_id=76233141')
  p parse('https://twitter.com/LoveLive_staff/status/1156374027180658690')
  p parse('http://ogp.me について教えて')
  p parse('https://gamebiz.jp/?p=241852 ogp')
end
