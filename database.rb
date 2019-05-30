require 'pg'
require 'sequel'

$result_map = ['nil', 'F', 'D', 'C', 'B', 'A', 'Pass', 'S', 'SS', 'SSS']

$table_name = :record

$DB = if ENV['RACK_ENV'] == 'production'
        Sequel.connect(ENV['DATABASE_URL'])
      else
        Sequel.postgres('piurecord', user: 'postgres', password: 'password',
                                     host: 'localhost')
      end

$DB.create_table $table_name do
  primary_key :song_id
  Integer :result, null: false
  Integer :difficulty, null: false
end

$record = $DB[$table_name]

def get_result(song_id)
  row = $record.where(song_id: song_id).first
  row.nil? ? '?' : $result_map[row[:result]]
end

def insert_result(song_id, result, difficulty)
  return unless 0 <= result && result < $result_map.length
  $DB["INSERT INTO #{$table_name} VALUES (?, ?, ?) " \
      "ON CONFLICT (song_id) DO UPDATE SET result = ?, difficulty = ?;",
      song_id, result, difficulty, result, difficulty].insert
end

def get_aggregate(difficulty)
  res = [0] * $result_map.length
  $DB.fetch("SELECT result, count(*) FROM #{$table_name} " \
            "WHERE difficulty = ? GROUP BY result", difficulty) do |row|
    res[row[:result]] = row[:count]
  end
  Hash[res.length.times.map { |idx| [$result_map[idx], res[idx]] }]
end
