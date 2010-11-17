$LOAD_PATH.unshift(File.dirname(__FILE__))

dir = File.dirname(__FILE__)
require File.join(dir,"..","lib","cubicle")
require "active_support"
require 'active_support/test_case'
require "shoulda"
require "logger"
require File.join(dir,"models","defect")
Cubicle.register_cubicle_directory(File.join(dir,"cubicles"))


module ActiveSupport
  class TestCase
    def setup
      dir = File.expand_path(File.dirname(__FILE__))
      logdir = File.join(dir,'log')
      Dir.mkdir(logdir) unless File.directory?(logdir)
      Cubicle.mongo.setup(YAML.load_file(File.join(dir,'config', 'database.yml')), "test", {
              :logger    => Logger.new(File.join(logdir,'test.log')),
              :passenger => false
      })
    end
    def teardown
      Cubicle.mongo.database.collections.each do |coll|
        coll.drop unless coll.name =~ /(.*\.)?system\..*/
      end
      Time.reset #Return Time.now to its original state
    end

    # Make sure that each test case has a teardown
    # method to clear the db after each test.
    def inherited(base)
      base.define_method teardown do
        super
      end
      base.define_method setup do
        super
      end
    end
  end
end
#This seems like an odd approach - why not just alias now, you ask
#well, I did, and for whatever reason, got stack overflows
#whenever I'd try to run the test suite. So...um...this doesn't
#overflow the stack, so it will do.
class Time
  @@old_now = method(:now)
  class << self
    def now=(new_now)
      @@new_now = new_now.to_time
      def Time.now
        @@new_now
      end
    end

    def reset
      def Time.now
        @@old_now.call
      end
    end
  end
end
