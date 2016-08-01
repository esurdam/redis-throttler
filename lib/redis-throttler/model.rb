module RedisThrottler
  module Model

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_eval { @limits ||= {} }
    end

    module ClassMethods
      # @param [Symbol] key
      # @param [Hash] opts
      def throttle(key, opts = {})
        klass = self.to_s.downcase
        key = "#{key.to_s}"

        subject = opts[:by] || :id
        limit = opts[:limit] || 5
        threshold = opts[:for] || 900
        interval = opts[:interval] || 5

        limiter = RedisThrottler::Base.new("#{klass}:#{key}", bucket_interval: interval, bucket_span: threshold)
        @limits[key] = "#{subject.to_s} limit #{limit} per #{threshold} sec"

        # includes('?') will return true
        method = "#{key}_limiter"

        %w(limits limits?).each do |string|
          define_singleton_method(string) { string.include?('?') || @limits }
          define_method(string) { string.include?('?') || @limits }
        end

        # i used Procs because they don't complain about arity
        # these Procs will return a string to be evaluated in context

        methods = {
            :exceeded? => proc { |to_call| "#{method}.exceeded? \"#{to_call}\", threshold: #{limit}, interval: #{threshold}" },
            :increment => proc { |to_call| "#{method}.add(\"#{to_call}\")" },
            :count => proc { |to_call, within| "#{method}.count(\"#{to_call}\", #{within})" }
        }

        # define the class & instance methods
        # pass the id to access counters
        define_singleton_method(method) { limiter }
        define_method(method) { self.class.send method }

        methods.each do |magic, meth|
          define_singleton_method("#{key}_#{magic.to_s}") { |id, within = threshold| eval meth.call(id, within) }
          define_method("#{key}_#{magic.to_s}") { |within = threshold| eval meth.call("#{self.send subject}", within) }
        end

      end
    end
  end
end