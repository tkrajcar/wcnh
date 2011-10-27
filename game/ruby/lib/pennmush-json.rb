#
# Public API for PennMUSH JSON.
#

# System modules.
require 'logger'
require 'pathname'

# Application modules.
require 'pennmush-json-conversation'

module PennJSON
  LOGGER = Logger.new(STDOUT)

  OBJECT_REGISTRY = {}
  @@expected_name = nil

  # Configuration values. Initially loaded with default values.
  SEARCH_PATH = ['pennmush-json']

  # Base PennJSON protocol error class.
  class ProtocolError < RuntimeError
    def initialize(code, message)
      super(message)

      @code = code
    end
  end

  # Local PennJSON protocol error class.
  class LocalError < ProtocolError
    # Get as a protocol error message.
    def to_json
      return { :error => { :code => @code, :message => message } }
    end
  end

  # Remote PennJSON protocol error class.
  class RemoteError < ProtocolError
    # Get as exception from protocol error message.
    def self.from_json(object)
      error = object['error']

      super(error['code'], error['message'])
    end
  end

  # Remote PennMUSH API.
  class Remote
    # Proxy unknown invocations to remote PennMUSH. Throws RemoteError in the
    # event the remote call responds with an error.
    def self.method_missing(name, *args)
      return PennJSON_Conversation.remote_invoke(name, *args)
    end

    # Set the context hash. If we had to deal with threads, this would need to
    # be thread-local. But we're intentionally using a multiprocess model.
    def self.set_context(context)
      old = @context
      @context = context
      return old
    end

    # Get a context value.
    def self.[](name)
      return @context.nil? ? nil : @context[name]
    end
  end

  # Panic in response to unrecoverable failures.
  def self.panic(message)
    raise Exception, message
  end

  # Register an object. If no name is given, will use object.name. Note that
  # some subtle search bugs are possible if the same name is used by multiple
  # modules. Try not to do that.
  def self.register_object(object, name=nil)
    if not name
      begin
        name = object.name
      rescue NoMethodError
        panic 'Incompatible object'
      end
    end

    if not name or name.empty?
      panic 'Anonymous object'
    end

    if name != @@expected_name
      panic "Expected '#{@@expected_name}', registering '#{name}'"
    end

    OBJECT_REGISTRY[name] = object

    name
  end

  # Resolve a name to an object.
  def self.resolve_object(name)
    # Try to resolve name.
    object = OBJECT_REGISTRY[name]
    return object if object

    # Guess that the object is defined by a file of the same name.
    begin
      # TODO: This logic could be made more complicated if we wanted to try
      # alternate cases and that sort of thing. But I prefer case sensitivity.
      found = false

      old_expected_name = @@expected_name
      @@expected_name = name
      begin
        SEARCH_PATH.each do |remote_path|
          searchstr = remote_path.to_s + "/**/" + name + ".rb"
          search = Dir.glob(searchstr)
          if search.length > 1
            raise LocalError.new(-32601, 'Multiple object definitions found')
          elsif search.length == 1 
            LOGGER.info "Loading '#{name}' from #{search[0]}"
            require search[0]
            found = true
            break # break out on first success
          end
        end
      ensure
        @@expected_name = old_expected_name
      end

      raise LocalError.new(-32601, 'Object definition not found') unless found
    rescue LoadError
      raise LocalError.new(-32601, 'Failed to load object definition')
    end

    # Try to resolve name again after require.
    object = OBJECT_REGISTRY[name]
    return object if object

    raise LocalError.new(-32601, 'Object not registered')
  end

  # Resolve a name to a method on an object.
  def self.resolve_method(object, name)
    begin
      return object.method('pj_' + name)
    rescue NameError
      raise LocalError.new(-32601, 'Method not found')
    end
  end

  # Configuration loader.
  def self.configure(config_yml)
    # Load values from configuration file.
    if File.exists? config_yml
      yml = YAML.load_file config_yml

      load_paths = yml['load_paths']
      if load_paths
        SEARCH_PATH.replace(yml['load_paths'])
      end
    end

    # Process loaded configuration.
    SEARCH_PATH.each_index do |idx|
      path = Pathname.new(SEARCH_PATH[idx]).realpath

      # Add path + /lib to Ruby load path. .to_s is not strictly needed, but we
      # don't want to confuse anyone else inspecting $:.
      $:.push((path + 'lib').to_s)

      # Add path + /remote to remote load path.
      SEARCH_PATH[idx] = path + 'remote'
    end
  end
end
