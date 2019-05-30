require 'pg'
require 'sequel'

$result_map = ['nil', 'F', 'D', 'C', 'B', 'A', 'Pass', 'S', 'SS', 'SSS']

$table_name = :record

$DB = if ENV['RACK_ENV'] == 'production'
        Sequel.connect(ENV['DATABASE_URL'])
      else
        Sequel.postgres('piurecord', user: 'postgres', password: 'password', host: 'localhost')
      end
$DB.create_table $table_name do
  primary_key :song_id
  Integer :result, null: false
end

$record = $DB[$table_name]

def get_result(song_id)
  row = $record.where(song_id: song_id).first
  row.nil? ? $result_map[0] : $result_map[row[:result]]
end

def insert_result(song_id, result)
  return unless 0 <= result && result < $result_map.length
  $DB["INSERT INTO #{$table_name} VALUES (?, ?) ON CONFLICT (song_id) DO UPDATE SET result = ?;", song_id, result, result].insert
end
