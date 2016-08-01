require 'spec_helper'

describe TestClass do

  it 'should be able to define throttle' do
    expect(TestClass).to respond_to :throttle
  end

  it 'should have a throttler for defined throttle' do
    expect(TestClass.logins_throttler.class).to eq(RedisThrottler::Base)
  end

  it 'should display limits as hash' do
    expect(TestClass.limits).to be_a(Hash)
  end

  it 'should respond to limits? correctly' do
    expect(TestClass.limits?).to eq(true)
  end

  it 'should be able to increment throttler by subject' do
    TestClass.logins_increment('testid')
    TestClass.logins_increment('testid')
    expect(TestClass.logins_count('testid')).to eq(2)
  end

  it 'should responsd to exceeded? correctly' do
    TestClass.logins_throttler.add('testid', 10)
    expect(TestClass.logins_exceeded?('testid')).to eq(true)

    TestClass.logins_throttler.add('testid2', 9)
    expect(TestClass.logins_exceeded?('testid2')).to eq(false)
  end

  it 'should not be rate-limited after interval' do
    expect(TestClass.logins_exceeded?('test3')).to eq(false)
    10.times { TestClass.logins_increment('test3') }
    expect(TestClass.logins_exceeded?('test3')).to eq(true)
    Timecop.travel(60) do
      expect(TestClass.logins_exceeded?('test3')).to eq(false)
    end
  end

  it 'should return counter value for subject within defined limits' do
    10.times { TestClass.logins_increment('test4') }
    expect(TestClass.logins_count('test4')).to eq(TestClass.logins_throttler.count('test4', 60))
  end
end
