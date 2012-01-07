#! /usr/bin/env ruby

#
# Quick and dirty helper script to allow testing main.rb using stdin/stdout.
#

require 'socket'

PATH_TO_RUBY = 'ruby'

s1, s2 = UNIXSocket.pair

read_set = [STDIN, s1]

def copy_io(io1, io2, sep)
  buf = io1.readpartial(8192)
  io2.write(buf)
  io2.write(sep)
  io2.flush()
end

fork do
  s1.close
  exec(PATH_TO_RUBY, 'main.rb', s2.fileno.to_s)
end
s2.close

while true
  ready = select(read_set)
  if ready
    ready_read = ready[0]

    if ready_read.include? STDIN
      copy_io(STDIN, s1, '')
    end

    if ready_read.include? s1
      copy_io(s1, STDOUT, $\)
    end
  end
end
