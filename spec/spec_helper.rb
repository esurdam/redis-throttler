require 'rspec'
require 'redis-throttler'
require 'redis-throttler/base'
require 'timecop'

class TestClass
  include RedisThrottler
  throttle :logins, limit: 10, for: 5000

  def initialize
    @id = 1234
  end

  def id
    @id
  end
end

@test = TestClass.new