require 'wcnh'

module Sysinf
  PennJSON::register_object(self)

  def self.pj_load_path(*args)
    return "#{titlebar "Ruby Load Path"}\n#{$LOAD_PATH.inspect}\n#{footerbar}"
  end
end
