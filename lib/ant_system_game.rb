require 'rubygems'
require 'pstore'


class AntSystemGame
  DEFAULT_TRAIL_LEVEL = 0.1
  attr_reader :root, :db
  def initialize(rules, args = {})
    @root = rules.new
    @db = Hash.new(DEFAULT_TRAIL_LEVEL)
    @constructed_solution = {}
    @alpha = 2
    @beta = 0.9
    @evaporation_rate = 0.9
    @quality_coefficient = 1.0
  end

  def tabu?(u, v)
    false
  end

  def trail
    @db
  end

  def run!(total_iterations, ants_in_iteration)
    total_iterations.times do |i|
      local_solution = construct_iteration(ants_in_iteration)
      apply_local_to_global(local_solution)
    end
    self
  end

  def save_global_trails(filename)
    store = PStore.new(filename)
    store.transaction do  # begin transaction; do all of this or none of it
      @db.each do |key, value|
        store[key] = value
      end
    end
  end

  def load_global_trails(filename)
    store = PStore.new(filename)
    @db = Hash.new(DEFAULT_TRAIL_LEVEL)
    store.transaction do
      store.roots.each do |key|
        @db[key] = store[key]
      end
    end
  end

  def apply_local_to_global(local_solution)
    evaporate_global
    add_to_global_trails local_solution
  end

  def evaporate_global
    @db.each_key do |key|
      evaporate_trail key
    end
  end

  def construct_iteration(n)
    result = []
    n.times do
      result << construct_one_trail
    end
    result
  end

  def evaporate_trail(key)
    trail[key] *= @evaporation_rate
  end

  def add_to_global_trails(iterations)
    prepare_local_update(iterations).each do |key, value|
      trail[key] += value
    end
  end

  def prepare_local_update(solutions)
    trails = Hash.new(0.0)
    # vytvorit sumu vsech cest
    solutions.each do |solution|
      p_quality = path_quality(solution)
      solution.each do |position|
        trails[position] += p_quality
      end
    end
    trails
  end

  def solution
    @db
  end

  def construct_one_trail
    path = [@root]
    tabu_list = []
    until path.last.final?
      step = next_step path.last, tabu_list
      path << step
    end
    path.map(&:hash)
  end

  def next_step position, tabu_list
    paths = get_all_paths_from position, tabu_list
    probabilities = paths.map {|path| probability(position, path, 0, tabu_list)}
    path_probabilities = paths.zip probabilities
    picked_number = rand
	  path_probabilities.each { |pair|
	    path = pair.first
	    prob = pair.last
		  picked_number -= prob
		  return path if picked_number <= 0.0
	  }
    puts path_probabilities.inspect
    puts picked_number
    puts "error on weighted random"
  end

  def probability(u, v, k = 0, tabu_list = [])
    this_path = desirability(v)
    all_paths = get_all_paths_from(u, tabu_list)
    suma = all_paths.map{|target| desirability(target)}.inject(&:+)
    return this_path.to_f / suma
  end

  def get_all_paths_from u, tabu_list = []
    targets = (u.moves - tabu_list).map{|move| u.dup.apply!(move)}
    #    targets.map { |target| [u, target.first, target.last]}
  end

  def path_quality(path)
    last_board = @root.new(path.last)
    #    p last_board.hash
    # worse => higher coeff modiff
    if last_board.winner == :white then
      quality_coeff_modif = 0.2
    elsif last_board.winner == :black then
      quality_coeff_modif = 2
    elsif last_board.draw? then
      quality_coeff_modif = 1.1
    else
      quality_coeff_modif = 1
    end
    @quality_coefficient / quality_coeff_modif
  end
  
  def attractiveness(v)
    if v.winner == :white then
      return 100
    elsif v.winner == :black then
      return 0
    elsif v.draw? then
      return 2
    else
      return 3
    end
  end

  def modified_trail_level(v)
    trail[v.hash] **  @alpha
  end

  def modified_attractiveness(v)
    attractiveness(v) ** @beta
  end

  def desirability(v)
    modified_trail_level(v) + modified_attractiveness(v)
  end
end

