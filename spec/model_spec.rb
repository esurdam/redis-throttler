require 'spec_helper'

describe TestClass do

  # we will test the firstly defined throttle
  before do
    throttle = TestClass.instance_variable_get(:@limits)
    key = throttle.keys[0]
    @count_to_fail = throttle[key][:limit]
    @time_til_okay = throttle[key][:threshold]
  end

  it 'Klass.throttle' do
    expect(TestClass).to respond_to :throttle
  end

  it '.limits' do
    expect(TestClass.limits).to be_a(Hash)
  end

  it '.limits?' do
    expect(TestClass.limits?).to eq(true)
  end

  it '.#{key}_throttler' do
    expect(TestClass.logins_throttler.class).to eq(RedisThrottler::Base)
  end

  it '.#{key}_increments(id)' do
    TestClass.logins_increment('testid')
    TestClass.logins_increment('testid')
    expect(TestClass.logins_count('testid')).to eq(2)
  end

  it '.#{key}_exceeded?(id)' do
    TestClass.logins_throttler.add('testid', 10)
    expect(TestClass.logins_exceeded?('testid')).to eq(true)

    TestClass.logins_throttler.add('testid2', 9)
    expect(TestClass.logins_exceeded?('testid2')).to eq(false)
  end

  it 'counts right' do
    @count_to_fail.times { TestClass.logins_increment('test4') }
    expect(TestClass.logins_count('test4')).to eq(TestClass.logins_throttler.count('test4', 60))
  end

  it 'recovers after limit passed' do
    expect(TestClass.logins_exceeded?('test3')).to eq(false)
    @count_to_fail.times { TestClass.logins_increment('test3') }

    expect(TestClass.logins_exceeded?('test3')).to eq(true)
    Timecop.travel(@time_til_okay) do
      expect(TestClass.logins_exceeded?('test3')).to eq(false)
    end
  end
end
