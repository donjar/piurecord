require 'net/http'
require 'json'

$api_uri = URI('https://pumpout2.anyhowstep.com:17593/api/search/result')
$search_id = {
  21 => '4c7172d577a2b4621fd31a86dd76abef',
  22 => 'b4ee3f64e43f195e532b2ecb4126a65a',
  23 => '2fb236c4ab7ab050fff144d7c3446817',
  24 => '406871232e4d445c0902977b673937ff',
  25 => 'c6c316166a8ff31b0237496e74a85fa0',
  26 => '067897b42c6dcd429174892c0a89776f'
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
  params = { atVersion: '147', languageCode: 'en', display: 'CHART', page: page, rowsPerPage: '100', searchId: search_id }

  uri = $api_uri
  uri.query = URI.encode_www_form(params)
  resp = JSON.parse(Net::HTTP.get(uri))
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
  end
end
