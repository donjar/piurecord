require 'net/http'
require 'net/https'
require 'json'

$api_uri = URI('https://pumpout2.anyhowstep.com:17593/api/search/result')
$search_id = {
  20 => 'bd2e8732ff22aee8360b5e0986d62a7f',
  21 => '4c7172d577a2b4621fd31a86dd76abef',
  22 => 'b4ee3f64e43f195e532b2ecb4126a65a',
  23 => '2fb236c4ab7ab050fff144d7c3446817',
  24 => '406871232e4d445c0902977b673937ff',
  25 => 'c6c316166a8ff31b0237496e74a85fa0',
  26 => '067897b42c6dcd429174892c0a89776f',
  27 => 'd8c9513f4ab7b0856dbca622176a25ab',
  28 => '22c1878e69b7988a252b36c1b351a042',
  50 => 'b7f59ccde3d06800b4c9fd347a25a1d8'
}

def process_response(resp)
  Hash[resp["rows"].flat_map do |song|
    title = song['internalTitle']
    cut = song['cut']['internalTitle']
    song['charts'].map do |chart|
      next unless chart['inVersion']
      id = chart['chartId']
      mode = chart['rating']['mode']['internalAbbreviation']
      diff = chart['rating']['difficulty']['internalTitle']
      [id, { song: "#{title} (#{cut})", difficulty: "#{mode}#{diff}" }]
    end.compact
  end]
end

def get_data(search_id, page)
  params = { atVersion: '152', languageCode: 'en', display: 'CHART', page: page, rowsPerPage: '100', searchId: search_id }

  uri = $api_uri
  uri.query = URI.encode_www_form(params)

  req = Net::HTTP::Get.new(uri.path)
  res = Net::HTTP.start(
          uri.host, uri.port, 
          :use_ssl => uri.scheme == 'https', 
          :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
    https.request(req)
  end
  resp = JSON.parse(res)
  { data: process_response(resp), max_page: resp['info']['pagesFound'] }
end

def get_all_data(search_id)
  page = 0
  {}.tap do |all_data|
    loop do
      res = get_data(search_id, page)
      all_data.merge!(res[:data])
      page + 1 < res[:max_page] ? page += 1 : break
    end
  end.sort_by do |id, data|
    match = /^(.*) \((.*)\)$/.match(data[:song])
    [data[:difficulty], match[2], match[1]]
  end
end
