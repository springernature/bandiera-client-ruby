require 'bundler'
Bundler.setup(:default, :test)

ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'webmock/rspec'

require_relative '../lib/bandiera'

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.order = 'random'
end
