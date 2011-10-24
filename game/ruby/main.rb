#! /usr/bin/env ruby

#
# Ruby implementation of PennMUSH JSON conversation server.
#

# External modules.
require './environment'

# Application modules.
require 'pennmush-json'
require 'pennmush-json-conversation'

# Startup code.
if ARGV.length < 1
  raise ArgumentError, 'Missing socket argument'
else
  PennJSON_Conversation.set_socket(Integer(ARGV[0]))
end

PennJSON::LOGGER.info 'Starting.'

begin
  PennJSON_Conversation.run()
rescue SystemExit
  PennJSON::LOGGER.warn "Terminating: #{$!}"
end
