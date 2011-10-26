# Initialize Bundler.
require 'rubygems'
require 'bundler/setup'

# Additional modules.
$:.push('.') unless $:.include? '.' # required for 1.9.2 compatibility
$:.push('lib')
$:.push('example') # for Ping.rb and any other future basic-test modules
if File.exists?("config.yml")
  yml = YAML.load_file "config.yml"
  yml["load_paths"].each do |path| 
    $:.push *Dir.glob(File.expand_path(path + "/**"))
  end
end
