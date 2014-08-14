$LOAD_PATH.unshift File.join(__FILE__, '../../lib')

require 'bundler'
Bundler.setup(:default, :test)

ENV['RACK_ENV'] = 'test'

require 'macmillan/utils/rspec/rspec_defaults'
require 'macmillan/utils/rspec/webmock_helper'
require 'macmillan/utils/test_helpers/codeclimate_helper'
require 'macmillan/utils/test_helpers/simplecov_helper'
require 'pry'

require 'bandiera/client'
