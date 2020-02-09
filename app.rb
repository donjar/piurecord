# frozen_string_literal: true

require 'sinatra'
require_relative 'pumpout.rb'
require_relative 'database.rb'

get '/' do
  ''.tap do |page|
    $search_id.keys.each do |k|
      page << "<a href='/#{k}'>#{k}</a><br>"
    end
  end
end

get '/:difficulty' do |difficulty|
  data = get_all_data($search_id[difficulty.to_i])
  haml :difficulty, locals: { difficulty: difficulty, chart_data: data }
end

get '/:difficulty/:song_id/:result' do |difficulty, song_id, result|
  insert_result(song_id.to_i, result.to_i, difficulty)
  redirect to("/#{difficulty}")
end
