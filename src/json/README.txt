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
	JSON_CFLAGS=-pthread -I<path to YAJL headers>

   If YAJL is installed as a system library, the defaults should be fine.

3. Run config.status from the PennMUSH base directory:

	./config.status

   Note that you will need to do this every time you modify src/Makefile.in.

4. Optionally update src/json/json-config.h with desired settings.

   This includes the conversation server path. You may need to set the
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
calls.

An RPC may be initiated either by PennMUSH or the conversation server.
Recursive RPC is allowed, but no top-level RPCs may be initiated until the most
recent top-level RPC has returned. This closely resembles traditional
procedural programming.

PennMUSH-initiated example:
1. Player calls the rpc() function in soft code.
2. PennMUSH server initiates RPC.
3. Conversation server might respond with RPC requesting security information.
4. PennMUSH server returns security information.
5. Conversation server returns response to rpc().

Conversation server-initiated example:
1. Timer tick triggers notification event.
2. Conversation server initiates notification RPC.
3. PennMUSH might respond with RPC requesting further information.
4. Conversation server returns further information.
5. PennMUSH server returns acknowledgment of notification RPC.

Future
======
* Integrate into PennMUSH Autoconf configuration.
