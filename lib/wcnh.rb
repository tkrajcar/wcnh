# All universal modules, class extensions, etc.
require 'time'

class String
  def ccl(arg)
    self << arg
    if defined? PennJSON
      self << "%r"
    else
      self << "\n"
    end
  end
end
