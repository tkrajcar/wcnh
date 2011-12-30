Requirements
============
Minimum:
* PennMUSH 1.8.4 and its requirements (client)
* YAJL 1.0 (for JSON serialization)
* BSD sockets (for networking; Windows not supported)
* POSIX threads (for event handling threads; Windows not supported)
* Conversation server implementation

For the Ruby conversation server included in game/ruby:
* Ruby 1.8 or later
* RubyGems (included with Ruby 1.9 and later)
* Bundler gem (gem install bundler)
* All gems listed in the Gemfile (bundle install)

Installation
============
1. Apply the patch from the PennMUSH base directory:

	cd pennmush
	patch < json-server.diff

2. Manually configure src/Makefile.in to point to YAJL:

	JSON_LIB=-lyajl -L<path to YAJL library>
	JSON_CFLAGS=-I<path to YAJL headers>

   If YAJL is installed as a system library, the defaults should be fine.

3. Run config.status from the PennMUSH base directory:

	./config.status

   Note that you will need to do this every time src/Makefile.in changes.

4. Optionally update src/json/json-config.h with desired settings.

   These settings include the conversation server path. You may need to set the
   conversation server executable:

	chmod +x game/ruby/main.rb

   You may also need to adjust the bang at the start of any scripts:

	#! /usr/bin/env ruby

   You may to run Bundler to install any required Ruby gems:

	gem install bundler
	bundle install --gemfile=game/ruby/Gemfile

   The exact details may depend on your RubyGems configuration, such as whether
   you're using a private GEM_HOME.

5. Build and install PennMUSH as usual.

Programming model
=================
For simplicity, we use a sequential, synchronous RPC programming model;
everything happens in order on a single thread, in the form of remote procedure
calls within a single logical transaction. We assume that the communication
channel is low latency, high bandwidth, and reliable, as would be the case on
a local interprocess communication channel like Unix domain sockets.

To avoid race conditions involving both parties trying to initiate requests
simultaneously, technically all RPC transactions are initiated by the PennMUSH
server. However, the conversation server may send an asynchronous notification
to the PennMUSH server, requesting that the PennMUSH server initiate an RPC
transaction. This effectively allows the conversation server to initiate an RPC
transaction as well. No more than one notification may be pending at once.

Recursive RPC is allowed, but no new RPC transactions may be initiated until
the previous RPC transaction has completed. This closely resembles traditional
procedural programming.

An error response still requires unwinding the entire RPC transaction. There is
no early exit. This enables intermediate RPCs to attempt recovery, if desired.

Example of a PennMUSH-initiated transaction:
1. Player calls the rpc() function in soft code.
2. PennMUSH server sends player RPC, initiating a new transaction.
3. Conversation server might respond with RPC requesting security information.
4. PennMUSH server returns response to security RPC.
5. Conversation server returns response to player RPC, ending the transaction.

Example of a conversation server-initiated transaction:
1. Timer tick triggers notification event.
2. Conversation server sends solicitation for transaction.
3. If a transaction is outstanding, the PennMUSH server completes it first.
4. PennMUSH server sends acknowledgment RPC, initiating a new transaction.
5. The remainder is identical to a standard PennMUSH-initiated transaction.

Protocol messages
=================
Protocol messages are described in JSON format. Protocol messages are always
JSON objects. (That is, they begin with "{" and end with "}".)

We may adopt the JSON-RPC protocol at some point (probably 2.0 or later). These
messages are designed to loosely resemble JSON-RPC, but are not actually
JSON-RPC due to some differences in our programming model.

The syntax below is meant to be suggestive; any valid JSON corresponding to the
same object is valid, after dropping any ignorable values (see "Supported data
types").

REQUEST                 := { "method": methodDescriptor PARAMETERS CONTEXT }
PARAMETERS              := | , "params": parameters
CONTEXT                 := | , "context": contextObject
methodDescriptor        := conversation server implementation-specific string
parameters              := array of parameter strings
contextObject           := object of named context parameters

RESULT                  := { "result": result }
result                  := null | result string

ERROR                   := { "error": { "code": code, "message": message } }
code                    := error code integer
message                 := error message string

SOLICITATION            := { "method": "rpc.req" }
ACKNOWLEDGEMENT         := { "method": "rpc.ack" }

Supported data types
====================
Currently, only a limited number of data types are supported:

1. Parameters may be an array of strings, or omitted entirely.
2. Results may be null or a string.
3. Error codes may be a 32-bit signed integer.
4. Error messages may be a string.
5. All other unknown keys or values should be silently ignored.

An unsupported type is a non-fatal error. The remainder of the message should
be parsed, and an appropriate error response returned.

The intent behind these rules is to support the least common denominator of
data types. The set of data types may be expanded at a later date.

Standard error codes
====================
Error codes -32768 to -32000 are reserved.

code    message           meaning
------  ----------------  ----------------------------------------------------
-32700  Parse error       Received JSON could not be parsed. Session will
                          likely be terminated instead of sending this
                          response, since parse state is probably unknown.

-32600  Invalid Request   Invalid protocol message received. Session will
                          likely be terminated instead of sending this
                          response, since protocol state is probably unknown.

-32601  Method not found  Method not found.

-32602  Invalid params    Invalid method parameters.

-32603  Internal error    Internal protocol error.

-32099  Server error      Implementation-specific server errors.
   ...
-32000

Reserved names and numbers
==========================
Method names beginning with "rpc." are reserved for internal use.

Known issues
============
* Using @shutdown/reboot while the conversation server is running may leave
  behind a zombie process. This is because PennMUSH might not reap the process
  before it restarts. Use "@rpc stop" to stop the conversation server before
  rebooting. This will also clean up any lingering zombie processes.

Future
======
* Support delta compression of the context.
* Support runtime configuration.
* Support TCP converation server implementations. (JRuby, for example.)
* Support more data types.
* Support more conversation server implementations.
* Support multiple simultaneous conversation server instances.
* Support persistent conversation server instances with lives beyond the MUSH.
* Integrate into PennMUSH Autoconf configuration?
