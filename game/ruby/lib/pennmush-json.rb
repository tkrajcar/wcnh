#
# Public API for PennMUSH JSON.
#
require 'logger'
require 'pennmush-json-conversation'

module PennJSON
  LOGGER = Logger.new(STDOUT)

  OBJECT_REGISTRY = {}

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

  # Register an object.
  def self.register_object(object)
    begin
      name = object.name
    rescue NoMethodError
      raise 'Incompatible object'
    end

    if not name or name.empty?
      raise 'Anonymous object'
    end

    OBJECT_REGISTRY[name] = object

    nil
  end

  # Resolve a name to an object.
  def self.resolve_object(name)
    # Try to resolve name.
    object = OBJECT_REGISTRY[name]
    return object if object

    # Guess that the object is defined by a file of the same name.
    begin
      require name
    rescue LoadError
      raise LocalError.new(-32601, 'Object definition not found')
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
end
