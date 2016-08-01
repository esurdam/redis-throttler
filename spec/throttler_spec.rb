require 'spec_helper'

describe RedisThrottler::Base do

  before do
    @rl = RedisThrottler::Base.new('test')
    @rl.send(:redis).flushdb
  end

  it 'sets set_bucket_expiry to the bucket_span if not defined' do
    expect(@rl.instance_variable_get(:@bucket_span)).to eq(@rl.instance_variable_get(:@bucket_expiry))
  end

  it 'does not allow bucket count less than 3' do
    expect do
      RedisThrottler::Base.new('test', {:bucket_span => 1, :bucket_interval => 1})
    end.to raise_error(ArgumentError)
  end

  it 'does not allow bucket_expiry > bucket_span' do
    expect do
      RedisThrottler::Base.new("key", {:bucket_expiry => 1200})
    end.to raise_error(ArgumentError)
  end

  it '.add(\'string\', 1)' do
    @rl.add('value1')
    @rl.add('value1')
    expect(@rl.count('value1', 1)).to eq(2)
    expect(@rl.count('value2', 1)).to eq(0)
    Timecop.travel(60) do
      expect(@rl.count('value1', 1)).to eq(0)
    end
  end

  it '.add(\'string\', 3)' do
    @rl.add('value1', 3)
    expect(@rl.count('value1', 1)).to eq(3)
  end

  it '.add(123, 1)' do
    @rl.add(123)
    @rl.add(123)
    expect(@rl.count(123, 1)).to eq(2)
    expect(@rl.count(124, 1)).to eq(0)
    Timecop.travel(10) do
      expect(@rl.count(123, 1)).to eq(0)
    end
  end

  it '.count' do
    counter_value = @rl.add("value1")
    expect(@rl.count("value1", 1)).to eq(counter_value)
  end

  it '.exceeded?' do
    5.times do
      @rl.add("value1")
    end

    expect(@rl.exceeded?("value1", {:threshold => 10, :interval => 30})).to be false
    expect(@rl.within_bounds?("value1", {:threshold => 10, :interval => 30})).to be true

    10.times do
      @rl.add("value1")
    end

    expect(@rl.exceeded?("value1", {:threshold => 10, :interval => 30})).to be true
    expect(@rl.within_bounds?("value1", {:threshold => 10, :interval => 30})).to be false
  end

  it 'accepts a threshold and a block that gets executed once it\'s below the threshold' do
    expect(@rl.count("key", 30)).to eq(0)
    31.times do
      @rl.add("key")
    end
    expect(@rl.count("key", 30)).to eq(31)

    @value = nil
    expect do
      Timeout.timeout(1) do
        @rl.exec_within_threshold("key", {:threshold => 30, :interval => 30}) do
          @value = 2
        end
      end
    end.to raise_error(Timeout::Error)
    expect(@value).to be nil
    Timecop.travel(40) do
      @rl.exec_within_threshold("key", {:threshold => 30, :interval => 30}) do
        @value = 1
      end
    end
    expect(@value).to be 1
  end

  it 'counts correctly when bucket_span equals count-interval ' do
    @rl = RedisThrottler::Base.new('key', {:bucket_span => 10, bucket_interval: 1})
    @rl.add('value1')
    expect(@rl.count('value1', 10)).to eql(1)
  end

end
