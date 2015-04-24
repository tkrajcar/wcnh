# All includes used by any script should go here.
require 'time'
require 'mongoid'

# Go find our MUSH library.
$:.push(File.expand_path("game/ruby/lib"))
require 'pennmush-json'

# Add systems/lib to LOAD_PATH.
MY_REAL_PATH = File.expand_path("../", __FILE__)
$:.push(MY_REAL_PATH)

# Load all files in systems/lib.
require 'require_all'
require_all MY_REAL_PATH

# MongoDB configuration
Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("wcnh")
  config.persist_in_safe_mode = true
end
Mongoid.logger = Logger.new(STDOUT)

# Global timezone - reset this if MUSH server timezone is ever changed.
GAME_TIME = ActiveSupport::TimeZone["Pacific Time (US & Canada)"].utc_offset / 3600

def titlebar(arg)
  ">--".red + "[".bold.red + arg.to_s.bold + "]".bold.red + ("-" * (73 - arg.length) + "<").red
end

def footerbar
  ">-----------------------------------------------------------------------------<".red
end

def middlebar(text)
  ">-#{arg.center(77,'-').bold.yellow}-<".red
end

def middlebar(arg = "")
  arg.center(79,"-").red.gsub(arg,arg.bold.yellow)
end

def create_all_indexes
  ret = []
  $mongoid_classes.each do |klass|
    ret << klass.create_indexes
  end
  ret
end
