require 'lib/ant_system_game'
require '../piskvorky/lib/rules'
require 'ftools'

class Learner
  attr_accessor :system
  def initialize
  end

  def try(times, batch)
#    db_path =  File.join(File.expand_path( File.dirname(__FILE__)) , 'db', "#{times}x#{batch}.sqlite3")
#    db = SQLite3::Database.new db_path
#    sql = "
#      create table trails (
#        hash  varchar2(30) not NULL,
#        value varchar2(30) not NULL,
#        player_color char(1) not NULL,
#        primary key (hash, player_color)
#      );"
#    db.execute sql
    @system = AntSystemGame.new TicTacToe.new #, :database => File.join(File.expand_path( File.dirname(__FILE__)) , 'db', 'database.sqlite3'))
    @system.run! times, batch
   # File.move(db_path, './done', true)
    #puts @system.white_trails.sort.sort{|a,b| a.first.length <=> b.first.length}.inspect
    #puts @system.black_trails.sort.sort{|a,b| a.first.length <=> b.first.length}.inspect
  end
end

