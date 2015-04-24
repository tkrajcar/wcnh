# crazy Penn markup system for colors.

module PennColor
  extend self

  COLORS = {
    'black'   => 'x',
    'red'     => 'r',
    'green'   => 'g',
    'yellow'  => 'y',
    'blue'    => 'b',
    'magenta' => 'm',
    'cyan'    => 'c',
    'white'   => 'w'
  }

  EXTRAS = {
    'bold'      => 'h',
    'underline' => 'u',
    'invert'    => 'i',
    'flash'     => 'f'
  }

  # control codes.
  CODE_BEGIN = "\002"
  CODE_BEGINCOLOR = "c"
  CODE_ENDCOLOR = "c/"
  CODE_END = "\003"
  CODE_TAG_END = CODE_BEGIN + CODE_ENDCOLOR + CODE_END

  COLORS.each do |color, value|
    define_method(color) do # .red, .blue, etc
      colorize(self, :foreground => color)
    end

    define_method("on_#{color}") do #.on_red, .on_blue, etc
      colorize(self, :background => color)
    end

    COLORS.each do |highlight, value| # .red_on_blue, etc
      next if color == highlight
      define_method("#{color}_on_#{highlight}") do
        colorize(self, :foreground => color, :background => highlight)
      end
    end
  end

  EXTRAS.each do |extra, value| # .bold, .underline, etc
    define_method(extra) do
      colorize(self, :extra => extra)
    end
  end

  def colorize(string, options = {})
    colored = CODE_BEGIN + CODE_BEGINCOLOR
    colored << [color(options[:foreground]), color(options[:background]).upcase, extra(options[:extra])].compact * ''
    colored << CODE_END
    colored << string
    colored << CODE_TAG_END
  end

  def color(color_name)
    return "" unless color_name && COLORS[color_name]
    COLORS[color_name]
  end

  def extra(extra_name)
    return "" unless extra_name && EXTRAS[extra_name]
    EXTRAS[extra_name]
  end

  def remove_penn_ansi
    self.gsub(/\x02.*?\x03/,'')
  end
end unless Object.const_defined? :PennColor

String.send(:include, PennColor)