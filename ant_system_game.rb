require '../aco/lib/ant_system'
require 'rubygems'
require 'sqlite3'


class AntSystemGame < AntSystem
  attr_reader :root, :white_trails, :black_trails
  def initialize(rules, args = {})
    @root = rules.new
    @db = SQLite3::Database.new args[:database]
    initialize_trails
    @constructed_solution = {}
    @alpha = 6
    @beta = 0.9
    @evaporation_rate = 0.9
    @quality_coefficient = 1.0
  end

  def tabu?(u, v)
    false
  end

  def trail(key, color = nil)
    case color
    when :white
      color_statement = "and trails.player_color = 'w'"
    when :black
      color_statement = "and trails.player_color = 'b'"
    else
      color_statement = ""
    end

    result = @db.execute "select value, player_color from trails WHERE trails.hash = '#{key}' #{color_statement};"
    if result.size == 1 then
      return result.first.first.to_f
    elsif result.empty?
      return nil
    else
      return result
    end
  end

  def white_trails
    @db.execute "select hash, value from trails where trails.player_color = 'w';"
  end

  def black_trails
    @db.execute "select hash, value from trails where trails.player_color = 'b';"
  end

  def set_trail(key, value, color)
    if trail(key, color).nil? then
      insert_trail key, value, color
    else
      update_trail key, value, color
    end
  end

  def run!(total_iterations, ants_in_iteration)
    total_iterations.times do |i|
      white_iteration, black_iteration = construct_iteration(ants_in_iteration)
      pheromone_update(white_iteration, :update => :white)
      pheromone_update(black_iteration, :update => :black)
    end
    self
  end

  def attractiveness(u, v)
    1
  end

  def pheromone_update iterations, args = {}
    if args[:update] == :white
      sum = sum_iterations(iterations)
      #evaporace
      white_trails.each do |key, value|
        update_trail key, @evaporation_rate * value.to_f, :white
      end
      #puts "\nUPDATE\n"
      #puts "---------"
      #update
      sum.each do |key, value|
        v = trail(key, :white) || 0.0
        set_trail key, v + value, :white
      end
    elsif args[:update] == :black
      sum = sum_iterations(iterations)
      #evaporace
      black_trails.each do |key, value|
        update_trail key, @evaporation_rate * value.to_f, :black
      end
      #puts "\nUPDATE\n"
      #puts "---------"
      #update
      sum.each do |key, value|
        v = trail(key, :white) || 0.0
        set_trail key, v + value, :black
      end
    end
  end

  def solution
  end

  def construct_solution
    path = [@root]
    tabu_list = []
    until path.last.final?
      step = next_step path.last, tabu_list
      path << step
    end
    path
  end

  def construct_iteration(n)
    result_white = []
    result_black = []
    result_draw = []
    n.times do
      sol = construct_solution
      case sol.last.winner
      when :white then
        #puts "white won!"
        #puts sol.last.hash
        result_white << sol
      when :black then
        #puts "black won!"
        #puts sol.last.hash
        result_black << sol
      else
        #puts "shameful draw!"
        result_draw << sol #draws are needless - send them to fuckoff bag
      end
    end
    [result_white, result_black, result_draw]
  end


  def sum_iterations(iterations)
    sum = {}
    # vytvorit sumu vsech cest
    iterations.each do |iteration|
      iteration.inject do |first, last|
        sum[last.hash] ||= 0.0
        sum[last.hash] += path_quality(iteration)
        last
      end
    end
    sum
  end

  def trail_level(u, v, args = {})
    case args[:update]
    when :white then
      trail v, :white
    when :black then
      trail v, :black
    else
      @trails[v.hash]
    end
  end

  private
    #will initialize local trails. Global trails are managed by database.
    def initialize_trails
      @trails = Hash.new(0.0)
    end

    def get_all_paths_from u, tabu_list = []
      targets = (u.moves - tabu_list).map{|move| [move, u.dup.apply!(move)]}
      targets.map { |target| [u, target.first, target.last]}
    end

    def update_trail(key, value, color)
      #puts "Updating #{key}, '#{color}'"
      #puts "\nWHITEB0\n" if key == 'whiteb1'
      @db.execute "update trails set value = '#{value}' WHERE trails.hash = '#{key}' and trails.player_color = '#{translate_color_to_database color}';"
    end

    def insert_trail(key, value, color)
      #puts "Inserting #{key}, '#{color}'"
      @db.execute "insert into trails VALUES ('#{key}', '#{value.to_s}', '#{translate_color_to_database color}');"
    end

    def translate_color_to_database(color)
      case color
      when :white
       return 'w'
      when :black
        return 'b'
      else
        raise "Unknown Color"
      end
    end
end

