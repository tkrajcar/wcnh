#! /usr/bin/env ruby

#
# Ruby implementation of PennMUSH JSON conversation server.
#
# This script takes a single argument, the file descriptor of the socket to
# communicate on (usually meant to be one end of a Unix domain socket pair).
# The launcher is responsible for executing this script in the correct working
# directory, although the script could theoretically do it.
#
# All other configuration information is loaded from config.yaml, if present.
# If not present, sensible defaults are used.
#

# External modules.
require './environment'

# Application modules.
require 'pennmush-json'
require 'pennmush-json-conversation'

# Startup code.
PennJSON.configure('config.yml')

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
