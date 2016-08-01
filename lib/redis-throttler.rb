require 'redis'
require 'redis-throttler/model'

module RedisThrottler
  def self.included(base)
    base.include(RedisThrottler::Model)
  end
end