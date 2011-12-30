# All includes used by any script should go here.
require 'time'
require 'github-v3-api'
require 'mongoid'

# Go find our MUSH library.
$:.push(File.expand_path("../mush/game/ruby/lib"))
$:.push(File.expand_path("../wcnh_mush/game/ruby/lib"))
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

def titlebar(arg)
  ">--".red + "[".bold.red + arg.to_s.bold + "]".bold.red + ("-" * (73 - arg.length) + "<").red
end

def footerbar
  ">-----------------------------------------------------------------------------<".red
end

def middlebar(arg = "")
  arg.center(79,"-").red.gsub(arg,arg.bold.yellow)
end
