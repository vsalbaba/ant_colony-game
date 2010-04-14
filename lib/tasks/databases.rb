require 'sqlite3'

desc "Creates database for results"
task 'create' do
  db = SQLite3::Database.new "./db/database.sqlite3"
  sql = "
    create table trails (
      hash  varchar2(30) not NULL,
      value varchar2(30) not NULL,
      player_color char(1) not NULL,
      primary key (hash, player_color)
    );"
  db.execute sql
end

