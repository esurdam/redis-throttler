require 'spec_helper'

describe 'Instace of TestClass' do
  before do
    @test = TestClass.new
    throttle = TestClass.instance_variable_get(:@limits)
    key = throttle.keys[0]
    @count_to_fail = throttle[key][:limit]
    @time_til_okay = throttle[key][:threshold]
  end

  it 'includes RedisThrottler' do
    expect(@test).to be_a_kind_of(RedisThrottler)
  end

  it '.limits' do
    expect(@test.limits).to be_a(Hash)
  end

  it '.limits?' do
    expect(@test.limits?).to eq(true)
  end

  it '.#{key}_throttler' do
    expect(@test.logins_throttler.class).to eq(RedisThrottler::Base)
  end

  it '.#{key}_increment' do
    @test.logins_increment
    @test.logins_increment
    expect(@test.logins_count).to eq(2)
  end

  it '.#{key}_exceeded?' do
    @count_to_fail.times do
      @test.logins_increment
    end
    expect(@test.logins_exceeded?).to eq(true)
  end

  it 'counts right' do
    expect(@test.logins_count).to eq(TestClass.logins_count(@test.id))

    4.times { @test.logins_increment }

    Timecop.travel(@time_til_okay) do
      (@count_to_fail - 1).times do
        @test.logins_increment
      end

      expect(@test.logins_count(1)).to eq(@count_to_fail - 1)
      expect(@test.logins_exceeded?).to eq(false)
    end
  end


  it 'recovers after limit passed' do
    @count_to_fail.times do
      @test.logins_increment
    end
    expect(@test.logins_exceeded?).to eq(true)
    Timecop.travel(@time_til_okay) do
      expect(@test.logins_exceeded?).to eq(false)
    end
  end
end
