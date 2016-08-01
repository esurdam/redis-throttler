require 'redis'
require 'redis-throttler/model'
require 'redis-throttler/base'

module RedisThrottler
  def self.included(base)
    base.include(RedisThrottler::Model)
  end
end