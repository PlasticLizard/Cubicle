require "rubygems"
require "active_support"
require "mongo"
require "logger"

dir = File.dirname(__FILE__)
["mongo_environment",
 "ordered_hash_with_indifferent_access",
 "member",
 "member_list",
 "measure",
 "calculated_measure",
 "dimension",
 "ratio",
 "duration",
 "query/dsl/time_intelligence",
 "query/dsl",
 "query",
 "data/member",
 "data/level",
 "data/hierarchy",
 "data/table",
 "aggregation/aggregation_manager",
 "aggregation/map_reduce_helper",
 "aggregation/dsl",
 "aggregation",
 "aggregation/ad_hoc",
 "date_time",
 "support"].each {|lib|require File.join(dir,'cubicle',lib)}

require File.join(dir,"cubicle","mongo_mapper","aggregate_plugin") if defined?(MongoMapper::Document)

module Cubicle

  def self.register_cubicle_directory(directory_path, recursive=true)
    searcher = "#{recursive ? "*" : "**/*"}.rb"
    Dir[File.join(directory_path,searcher)].each {|cubicle| require cubicle}
  end

  def self.mongo
    @mongo ||= defined?(::MongoMapper::Document) ? ::MongoMapper : MongoEnvironment
  end

  def self.logger
    @logger ||= (Cubicle.mongo.logger || Logger.new("cubicle.log"))
  end 
end