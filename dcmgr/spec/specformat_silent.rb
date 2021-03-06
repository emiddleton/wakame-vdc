$:.unshift "#{File.dirname(__FILE__)}/../lib"

begin
  require File.expand_path('../../.bundle/environment', __FILE__)
rescue LoadError
  require "rubygems"
  require "bundler"
  Bundler.setup(:root=>File.expand_path('../../', __FILE__))
end
require 'logger'
require 'dcmgr'

logger = Logger.new(STDOUT)
logger.level = Logger::FATAL
Dcmgr.logger = logger

SPECFORMAT = true
