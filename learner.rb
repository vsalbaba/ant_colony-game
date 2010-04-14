require 'ant_system_game'
require '../piskvorky/lib/rules'
require 'rubygems'
require 'hammertime'
require 'active_record'

class Learner
  attr_accessor :system
  def initialize(aco_class, rules)
    @system = aco_class.new(rules.new, :database => File.join(File.expand_path( File.dirname(__FILE__)) , 'db', 'database.sqlite3'))
  end

  def try(times, batch)
    @system.run! times, batch
    #puts @system.white_trails.sort.sort{|a,b| a.first.length <=> b.first.length}.inspect
    #puts @system.black_trails.sort.sort{|a,b| a.first.length <=> b.first.length}.inspect
  end
end

