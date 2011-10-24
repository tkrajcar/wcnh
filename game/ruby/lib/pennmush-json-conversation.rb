#
# PennMUSH JSON conversation state machine.
#

# External modules.
require 'environment'
require 'yajl'

# Standard library modules.
require 'socket'
require 'thread'

# Application modules.
require 'pennmush-json'

module PennJSON_Conversation
  # Recursion limit, to prevent runaway stacks. This should probably be a lot
  # smaller than for local procedure calls, due to the extra latency involved
  # in unwinding the call stack.
  MAX_DEPTH = 5

  # I/O read size.
  MAX_READ_CHUNK = 65536

  # Identifier parsing regex: (ObjectName).(method_name_without_pj_prefix)
  ID_RE = /^([_A-Z][_A-Za-z0-9]*)\.([_A-Za-z][_A-Za-z0-9]*)$/

  # Callback queue.
  CALLBACK_QUEUE = Queue.new

  # Callback trigger pipe.
  CALLBACK_PIPE = IO.pipe

  # Callback trigger value.
  CALLBACK_DATA = 'P'

  # Panic in response to unrecoverable failures.
  def self.panic(message)
    raise Exception, message
  end

  # Helper method for clearing buffers.
  def self.do_clear(buf)
    # String#clear is only available in Ruby 1.9+
    buf.slice!(0..-1)
  end

  # Initialize our side of the socket pair.
  def self.set_socket(fd)
    @@conn = Connection.new(Socket.for_fd(fd))
  end

  # Execute event loop.
  def self.run
    @@depth = 0 # initial request depth
    @@soliciting = false # whether we're currently soliciting
    @@pipebuf = ''

    read_set = [@@conn.get_socket, CALLBACK_PIPE[0]]
    while true
      # Decide if we need to solicit for callback.
      if not @@soliciting and not CALLBACK_QUEUE.empty?
        @@conn.write_object(:may)
        @@soliciting = true
      end

      # Wait for events.
      ready = select(read_set)

      # Process events.
      if ready
        ready[0].each do |fd|
          if fd.equal? @@conn.get_socket
            # Handle start of transaction.
            dispatch(@@conn.read_object)
          elsif fd.equal? CALLBACK_PIPE[0]
            # Handle callback polling trigger.
            CALLBACK_PIPE[0].readpartial(MAX_READ_CHUNK, @@pipebuf)
            do_clear(@@pipebuf)
          end
        end
      end
    end
  end

  # Invoke the block on the event dispatch thread at some later point in time.
  # May be called safely from other threads.
  def self.invoke_later(&block)
    CALLBACK_QUEUE.push(block)
    CALLBACK_PIPE[1].write(CALLBACK_DATA)
  end

  # Dispatches initial message.
  def self.dispatch(message)
    if message['method']
      dispatch_method(message)
    elsif message['go']
      dispatch_callback
    else
      panic 'Malformed protocol message.'
    end
  end

  # Dispatches callback message.
  def self.dispatch_callback
    # Start transaction. Must be at least one callback, since we solicited.
    @@soliciting = :go
    begin
      CALLBACK_QUEUE.pop().call()
    rescue
      # Log non-fatal StandardError.
      PennJSON::Logger.error $!.inspect
    end

    # End transaction.
    @@conn.write_object(:done)
    @@soliciting = false
  end

  # Dispatches invocation message.
  def self.dispatch_method(message)
    @@depth += 1 # entering call; increase depth
    begin
      # Abort if recursion limit reached.
      if @@depth > MAX_DEPTH
        raise PennJSON::LocalError.new(-32603, 'Local recursion limit')
      end

      # Parse method identifier. We have very restrictive rules, to prevent
      # unintended exposure of sensitive APIs:
      #
      # 1. Identifiers are restricted to ASCII letters, digits, and underscore.
      # 2. A remotable method must have a local name starting with "pj_".
      # 3. A remotable method must be a method of a remotable object.
      # 4. A remotable object must register using PennJSON.register_object().
      # 5. A remotable object must be requirable by 'pennmush-json/ObjectName'.
      #
      # Note that the "pj_" prefix is not part of the remote method name; it is
      # only present on the local method name as a marker.
      if ID_RE =~ message['method']
        remotable = PennJSON::resolve_object($1)
        callable = PennJSON::resolve_method(remotable, $2)
      else
        raise PennJSON::LocalError.new(-32601, 'Invalid method identifier')
      end

      # Invoke the requested call.
      saved_context = PennJSON::Remote.set_context(message['context'])
      begin
        params = message['params']
        if params.nil?
          result = callable.call()
        elsif params.respond_to? :to_ary
          result = callable.call(*params.to_ary)
        elsif params.respond_to? :to_hash
          result = callable.call(params.to_hash)
        else
          raise PennJSON::LocalError.new(-32602, 'Invalid parameters')
        end
      rescue PennJSON::LocalError
        # Don't catch PennJSON::LocalError yet.
        raise
      rescue
        # Exceptions descending from StandardError are reported. All other
        # exceptions are considered fatal and will terminate the conversation.
        # Called method must perform its own exception handling in such cases.
        raise PennJSON::LocalError.new(-32603, $!.inspect)
      ensure
        PennJSON::Remote.set_context(saved_context)
      end

      response = { :result => result }
    rescue PennJSON::LocalError
      response = $!.to_json
    ensure
      @@depth -= 1 # leaving call; decrease depth
    end

    # Send response.
    @@conn.write_object(response)
  end

  # Invokes remote method.
  def self.remote_invoke(name, *args)
    @@depth += 1 # entering call; increase depth
    begin
      # Only allowed at @@depth == 1 if soliciting was acknowledged.
      if @@depth == 1 and @@soliciting != :go
        raise PennJSON::RemoteError.new(-32603, 'Unsolicited')
      end

      # Abort if recursion limit reached.
      if @@depth > MAX_DEPTH
        raise PennJSON::RemoteError.new(-32603, 'Local recursion limit')
      end

      # Invoke the requested call.
      if args.empty?
        request = { :method => name }
      elsif args.length == 1 and args[0].respond_to? :to_hash
        request = { :method => name, :params => args[0].to_hash }
      else
        request = { :method => name, :params => args }
      end

      @@conn.write_object(request)

      # Return the response.
      while true
        response = @@conn.read_object

        if response['result']
          # Successful result.
          return response['result']
        elsif response['method']
          # Recursive remote call; dispatch and wait for response again.
          dispatch_method(response)
        elsif response['error']
          # Error result.
          raise PennJSON::RemoteError.from_json(response)
        else
          # Invalid response.
          panic 'Malformed protocol message.'
        end
      end
    ensure
      @@depth -= 1 # leaving call; decrease depth
    end
  end

  # Connection class.
  class Connection
    # Initialize connection state.
    def initialize(sock)
      @sock = sock

      @inbuf = ''
      @parser = Yajl::Parser.new
      @encoder = Yajl::Encoder.new

      @parser.on_parse_complete = Proc.new do |object|
        PennJSON_Conversation.panic 'Protocol violation.' if @object
        @object = object
      end
    end

    # Get the socket.
    def get_socket
      return @sock
    end

    # Reads an object as JSON. This call blocks until an entire object is
    # received. The blocking is considered a feature.
    #
    # Note that it is a protocol violation for the PennMUSH server to send
    # multiple JSON objects without waiting for a reply, and therefore there is
    # no need to handle receiving multiple objects.
    def read_object
      # Incrementally parse next object.
      begin
        while not @object
          @sock.readpartial(MAX_READ_CHUNK, @inbuf)
          @parser << @inbuf
          PennJSON_Conversation.do_clear(@inbuf)
        end
      rescue Yajl::ParseError
        PennJSON_Conversation.panic 'Malformed protocol message.'
      rescue EOFError
        raise SystemExit, 'Remote closed connection.'
      end

      # Fetch parsed object. Could make this a queue, I suppose.
      result = @object
      @object = nil
      return result
    end

    # Writes an object as JSON. This call blocks until the entire object is
    # sent. The blocking is considered a feature.
    def write_object(object)
      @encoder.encode(object, @sock)
    end
  end
end
