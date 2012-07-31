require 'minitest/spec'
require 'minitest/autorun'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'maths'

def maths(code)
  @env.eval(code)
end

describe Maths do

  before do
    @env = Maths::Environment.new
  end

  it 'supports positive integers' do
    assert_equal 1, maths('1')
    assert_equal 1234567890, maths('1234567890')
  end

  it 'supports negative integers' do
    assert_equal -1, maths('-1')
    assert_equal -1234567890, maths('-1234567890')
  end

  it 'supports floats' do
    assert_equal 0.1, maths('0.1')
    assert_equal 0.1, maths('.1')
  end

  it 'supports negative floats' do
    assert_equal -0.1, maths('-0.1')
    assert_equal -0.1, maths('-.1')
  end

  it 'adds' do
    assert_equal 2, maths('1 + 1')
  end

  it 'subtracts' do
    assert_equal 4, maths('7 - 3')
  end

  it 'multiplies' do
    assert_equal 48, maths('6 * 8')
  end

  it 'divides' do
    assert_equal 5, maths('15 / 3')
  end

  it 'supports proper operator precedence' do
    assert_equal  7, maths('1 + 2 * 3')
    assert_equal -5, maths('1 - 2 * 3')
    assert_equal  3, maths('1 + 6 / 3')
    assert_equal -1, maths('1 - 6 / 3')

    assert_equal 11, maths('2 * 3 + 5')
    assert_equal  1, maths('2 * 3 - 5')
    assert_equal  6, maths('6 / 2 + 3')
    assert_equal  0, maths('6 / 2 - 3')
  end

  it 'allows parenthesis to manipulate eval order' do
    assert_equal  9, maths('(1 + 2) * 3')
    assert_equal 16, maths('2 * (3 + 5)')
  end

  it 'does not require spaces around operators' do
    assert_equal 2, maths('1+1')
    assert_equal 0, maths('1-1')
    assert_equal 1, maths('1*1')
    assert_equal 1, maths('1/1')
    assert_equal 4, maths('8+-4')
  end

  it 'does not require spaces around assignments' do
    maths('a=3')
  end

  it 'does not require spaces around parenthesis' do
    maths('4*(9-2)')
  end

  it 'handles multiline code' do
    assert_equal 2, maths("1\n1 + 1")
  end

  it 'sets and references a variable' do
    assert_equal 3, maths("a = 3\na")
  end

  it 'performs calculations with a variable' do
    assert_equal 5, maths("a = 2\na + 3")
  end

  it 'evals multiple scripts in the same context' do
    maths('a = 3')
    assert_equal 3, maths('a')
  end

  it 'raises an exception when referencing an undefined variable' do
    assert_raises Maths::Runtime::Error do
      maths('a')
    end
  end

  describe 'Print' do

    before do
      module Maths::Runtime
        class << self
          alias_method :old_puts, :puts
          attr_accessor :__output__
          def puts(*args)
            self.__output__.send(:<<, *args)
          end
        end
      end
      Maths::Runtime.__output__ = []
    end

    after do
      module Maths::Runtime
        class << self
          alias_method :old_puts, :puts
          remove_method :old_puts
        end
      end
    end

    it 'prints to the screen' do
      maths("Print 1")
      assert_equal [1], Maths::Runtime.__output__
    end

    it 'prints the value of anything to the right' do
      maths("Print (5 + 7) * 2.5")
      assert_equal [30.0], Maths::Runtime.__output__
    end
  end
end
