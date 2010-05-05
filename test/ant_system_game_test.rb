require 'test/unit'
require 'rubygems'
require 'shoulda'
require 'learner'
require 'mocha'

class AntSystemGameTest < Test::Unit::TestCase
  context 'ant system game' do
    setup do
      @it = AntSystemGame.new TicTacToe
    end
    should 'set and read trails' do
      assert_equal AntSystemGame::DEFAULT_TRAIL_LEVEL, @it.trail['a']
      @it.trail['a'] = 1.0
      assert_equal 1.0, @it.trail['a']
    end

    context 'attractiveness' do
      setup do
        @ttt = TicTacToe.new
      end

      should 'attractiveness should return 100 for white win' do
        @ttt.stubs(:final?).returns(true)
        @ttt.stubs(:winner).returns(:white)
        assert_equal 100, @it.attractiveness(@ttt)
      end

      should 'return 2 for draws' do
        @ttt.stubs(:draw?).returns(true)
        assert_equal 2, @it.attractiveness(@ttt)
      end

      should 'return 3 for nonfinal conditions' do
        @ttt.stubs(:final?).returns(false)
        assert_equal 3, @it.attractiveness(@ttt)
      end

      should 'attractiveness return 0 for loses' do
        @ttt.stubs(:final?).returns(true)
        @ttt.stubs(:winner).returns(:black)
        @ttt.stubs(:loser).returns(:white)
        assert_equal 0.0, @it.attractiveness(@ttt)
      end
    end
    context 'evaporation' do
      context 'evaporate global' do
        should 'evaporate all global trails' do
          @it.trail['w'] = 10.0
          @it.trail['b'] = 5.0
          @it.evaporate_global
          assert @it.trail['w'] < 10.0
          assert @it.trail['b'] < 5.0
        end
      end
      context 'evaporate trail' do
        should 'should change only specified trail' do
          @it.trail['w'] = 10.0
          @it.trail['b'] = 5.0
          @it.evaporate_trail('w')
          assert_equal 9.0, @it.trail['w']
          assert_equal 5.0, @it.trail['b']
        end
      end
    end

    context 'add to global trails' do
      should 'add local trails to global trails trails' do
        @it.add_to_global_trails([['whitea0', 'whitea0blacka1'],['whitea0', 'whitea0blacka2']])
        assert @it.trail['whitea0'] > AntSystemGame::DEFAULT_TRAIL_LEVEL
        assert @it.trail['whitea0blacka1'] > AntSystemGame::DEFAULT_TRAIL_LEVEL
      end
    end

    context 'prepare_local_update' do
      should 'should transfer iteration into trails' do
        iterations = [ ['whitea0', 'whitea0blackb1'],
          ['whitea0', 'whitea0blacka0'] ]
        iterations2 = @it.prepare_local_update iterations
        assert iterations2['whitea0'] > 0.0
        assert iterations2['whitea0blacka0'] > 0.0
      end
    end

    context 'apply_local_to_global' do
      should 'only add to keys which were not yet visited' do
        iteration = [ ['whitea0', 'whitea0blackb1'],
          ['whitea0', 'whitea0blacka0'] ]
        @it.apply_local_to_global(iteration)
        assert @it.trail['whitea0'] > AntSystemGame::DEFAULT_TRAIL_LEVEL
        assert_equal AntSystemGame::DEFAULT_TRAIL_LEVEL, @it.trail['whitea1']
      end
      should 'only evaporate to keys which were not visited this iteration' do
        iteration = []
        @it.trail['w'] = 5.0
        @it.apply_local_to_global(iteration)
        assert @it.trail['w'] < 5.0
      end
    end

    context 'probability' do
      should 'return 100% if there is only one way from u and it is to v' do
        ttt = TicTacToe.new
        @it.stubs(:get_all_paths_from).returns([ttt])
        assert_equal 1.0, @it.probability(ttt, ttt)
      end
    end

    context 'desirability' do
      should 'return higher values for winning games' do
        ttt = TicTacToe.new
        ttt.stubs(:winner).returns(:white)
        ttt.stubs(:final?).returns(true)
        tt2 = TicTacToe.new
        tt2.stubs(:final?).returns(false)
        assert @it.desirability(ttt) > @it.desirability(tt2)
      end
      should 'return lower values for losing games' do
        ttt = TicTacToe.new
        ttt.stubs(:winner).returns(:black)
        ttt.stubs(:final?).returns(true)
        tt2 = TicTacToe.new
        tt2.stubs(:final?).returns(false)
        assert @it.desirability(ttt) < @it.desirability(tt2)
      end
    end

    context 'path quality' do
      should 'evaluate high paths which end with win' do
        path = ["whitea0", "whitea0a1a2blackc0c1"]
        assert_equal 1.0/0.2 , @it.path_quality(path)
      end
      should 'evaluate low paths which end with lose do' do
        path = ["whitea0a1b0blackc0c1c2"]
        assert_equal 1.0/2 , @it.path_quality(path)
      end
      should 'evaluate lower than 1 paths which end with draw' do
        path = ["whitea1a2b0b1c2blacka0b2c0c1"]
        assert @it.path_quality(path) < 1.0
      end
    end
  end
end

