module Cubicle
  class MongoEnvironment

    # @api public
    def self.connection
      @@connection ||= Mongo::Connection.new
    end

    # @api public
    def self.connection=(new_connection)
      @@connection = new_connection
    end

    # @api public
    def self.logger
      connection.logger
    end

    # @api public
    def self.database=(name)
      @@database = nil
      @@database_name = name
    end

    # @api public
    def self.database
      if @@database_name.blank?
        raise 'You forgot to set the default database name: MongoMapper.database = "foobar"'
      end

      @@database ||= connection.db(@@database_name)
    end

    def self.config=(hash)
      @@config = hash
    end

    def self.config
      raise 'Set config before connecting. Cubicle.mongo.config = {...}' unless defined?(@@config)
      @@config
    end

    # @api private
    def self.config_for_environment(environment)
      env = config[environment]
      return env if env['uri'].blank?

      uri = URI.parse(env['uri'])
      raise InvalidScheme.new('must be mongodb') unless uri.scheme == 'mongodb'
      {
              'host' => uri.host,
              'port' => uri.port,
              'database' => uri.path.gsub(/^\//, ''),
              'username' => uri.user,
              'password' => uri.password,
              }
    end

    def self.connect(environment, options={})
      raise 'Set config before connecting. Cubicle.mongo.config = {...}' if config.blank?
      env = config_for_environment(environment)
      self.connection = Mongo::Connection.new(env['host'], env['port'], options)
      self.database = env['database']
      self.database.authenticate(env['username'], env['password']) if env['username'] && env['password']
    end

    def self.setup(config, environment, options={})
      using_passenger = options.delete(:passenger)
      handle_passenger_forking if using_passenger
      self.config = config
      connect(environment, options)
    end

    def self.handle_passenger_forking
      if defined?(PhusionPassenger)
        PhusionPassenger.on_event(:starting_worker_process) do |forked|
          connection.connect_to_master if forked
        end
      end
    end

    # @api private
    def self.use_time_zone?
      Time.respond_to?(:zone) && Time.zone ? true : false
    end

    # @api private
    def self.time_class
      use_time_zone? ? Time.zone : Time
    end

    # @api private
    def self.normalize_object_id(value)
      value.is_a?(String) ? Mongo::ObjectID.from_string(value) : value
    end
  end
end
#This class represents MongoDB. It is lifted line for line from MongoMapper
#http://github.com/jnunemaker/mongomapper/blob/master/lib/mongo_mapper.rb
#Actually, if the MongoMapper gem is loaded, Cubicle will simply use it for
#providing the MongoEnvironment. However, if MongoMapper isn't loaded,
#this stuff is still required, so why reinvent the wheel?
