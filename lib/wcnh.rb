# All universal modules, class extensions, etc.
require 'time'
require 'penncolor'


def titlebar(arg)
  ">--".red + "[".bold.red + arg.to_s.bold + "]".bold.red + ("-" * (73 - arg.length) + "<").red
end

def footerbar
  ">-----------------------------------------------------------------------------<".red
end