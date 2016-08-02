require 'redis'
require 'redis-throttler/configuration'
require 'redis-throttler/model'
require 'redis-throttler/base'


module RedisThrottler
  extend RedisThrottler::Configuration

  define_setting :default_limit, 5
  define_setting :default_threshold, 600

  define_setting :redis, Redis.new(host: '192.168.99.100', port: 32772)

  def self.included(base)
    base.include(RedisThrottler::Model)
  end
end