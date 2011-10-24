# Initialize Bundler.
require 'rubygems'
require 'bundler/setup'

# Additional modules.
$:.push('.') unless $:.include? '.' # required for 1.9.2 compatibility
$:.push('lib')
