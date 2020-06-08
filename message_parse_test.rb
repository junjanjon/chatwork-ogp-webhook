# frozen_string_literal: true

require_relative './message_parse'

if $PROGRAM_NAME == __FILE__
  p parse('https://www.pixiv.net/member_illust.php?mode=medium&illust_id=76233141')
  p parse('https://twitter.com/LoveLive_staff/status/1156374027180658690')
  p parse('http://ogp.me について教えて')
  p parse('https://gamebiz.jp/?p=241852 ogp')
end
