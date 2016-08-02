require 'redis'
require 'redis-throttler/configuration'
require 'redis-throttler/model'
require 'redis-throttler/base'


module RedisThrottler
  extend RedisThrottler::Configuration

  define_setting :default_limit, 5
  define_setting :default_threshold, 600

  define_setting :redis, Redis.new(host: 'localhost', port: 6379)

  def self.included(base)
    base.include(RedisThrottler::Model)
  end
end