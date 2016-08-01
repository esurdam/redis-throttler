require 'spec_helper'

describe 'Instace of TestClass' do
  before do
    @test = TestClass.new
  end

  it 'should have a throttler for defined throttle' do
    expect(@test.logins_throttler.class).to eq(RedisThrottler::Base)
  end

  it 'should display limits as hash' do
    expect(@test.limits).to be_a(Hash)
  end

  it 'should respond to limits? correctly' do
    expect(@test.limits?).to eq(true)
  end

  it 'should be able to increment throttler by subject' do
    @test.logins_increment
    @test.logins_increment
    expect(@test.logins_count).to eq(2)
  end

  it 'should responsd to exceeded? correctly' do
    10.times do
      @test.logins_increment
    end
    expect(@test.logins_exceeded?).to eq(true)
  end

  it 'should not be rate-limited after interval' do
    Timecop.travel(60) do
      expect(@test.logins_exceeded?).to eq(false)
    end
  end

  it 'should return counter value for subject within defined limits' do
    expect(@test.logins_count).to eq(TestClass.logins_count(@test.id))
  end
end
