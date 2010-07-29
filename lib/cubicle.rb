require "rubygems"
require "active_support"
require "active_support/hash_with_indifferent_access" unless defined?(HashWithIndifferentAccess)
require "mongo"
require "logger"
require "mustache"
require "time"

dir = File.dirname(__FILE__)
["mongo_environment",
 "ordered_hash_with_indifferent_access",
 "member",
 "member_list",
 "expansion",
 "measure",
 "calculated_measure",
 "dimension",
 "bucketized_dimension",
 "ratio",
 "difference",
 "duration",
 "query/dsl/time_intelligence",
 "query/dsl",
 "query",
 "data",
 "data/member",
 "data/level",
 "data/hierarchy",
 "data/table",
 "aggregation/aggregation_metadata",
 "aggregation/cubicle_metadata",
 "aggregation/aggregation_view",
 "aggregation/aggregation_manager",
 "aggregation/map_reduce_helper",
 "aggregation/dsl",
 "aggregation/profiler",
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

  #Offer an easy way to set cubicle up with configuration independent of mongo mapper even if mongo mapper
  #has been included. This is useful in a scenario where you want your map reduce activity to happen
  #on a different server, such as a slave, so that your transactional systems aren't constantly irritated
  #by all the loud crunching sounds that cubicle makes. Maybe someday map reduce will learn to chew with
  #its mouth shut. Until then, it may be prudent to let cubicle run on a slave, and mongo mapper on
  #your master.
  def self.setup(config,environment,options)
    @mongo = MongoEnvironment
    @mongo.setup(config,environment,options)
  end

  def self.mongo
    @mongo ||= defined?(::MongoMapper::Document) ? ::MongoMapper : MongoEnvironment
  end

  def self.mongo=(mongo_env)
    @mongo = mongo_env
  end

  def self.logger
    @logger ||= (Cubicle.mongo.logger || Logger.new("cubicle.log"))
  end

  def self.clear_temp_tables
    self.mongo.database.collection_names.each{|cn|self.mongo.database[cn].drop if cn =~ /tmp.mr.mapreduce/i}
  end

end

#Turn off HTML escaping in Mustache
class Mustache
  class Generator
    alias_method :off_utag, :on_utag
    alias_method :off_etag, :on_etag

    alias_method :on_utag, :off_etag
    alias_method :on_etag, :off_utag
  end
end
