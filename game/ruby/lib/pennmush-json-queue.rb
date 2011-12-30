#
# Callback queue.
#

require 'thread'

class PennJSON_Queue
  # Constructs a queue with the given maximum size. The maximum size will
  # actually be rounded up to the next power of 2 minus 1. For good
  # performance, try to pick a reasonably small maximum size.
  def initialize(max_size_hint)
    @max = 1
    while @max <= max_size_hint
      @max <<= 1
    end

    @max_mask = @max - 1
    # May want to check that @max_mask is still a Fixnum at this point.

    @queue = []
    @mutex = Mutex.new

    @head = 0
    @tail = 0
  end

  # Tests if the queue is currently empty. This method is thread-safe, although
  # the result may become out of date if multiple threads are draining the
  # queue. For the intended usage (draining only from event dispatch thread),
  # this should probably be fine.
  def empty?
    @mutex.synchronize do
      return @head == @tail
    end
  end

  # Adds an object to the queue, or raises a RuntimeError if the queue is full.
  # This method is thread-safe.
  def queue(object)
    @mutex.synchronize do
      # Check if the queue is full.
      next_tail = (@tail + 1) & @max_mask
      if next_tail == @head
        raise 'Queue full'
      end

      # Insert the new object.
      @queue[@tail] = object
      @tail = next_tail

      return self
    end
  end

  # Removes the oldest object from the queue, or returns nil if the queue is
  # empty. This method is thread-safe.
  def dequeue
    @mutex.synchronize do
      # Check if the queue is empty.
      if @head == @tail # not using empty? to avoid extra synchronize block
        return nil
      end

      # Remove next object.
      object = @queue[@head]
      @queue[@head] = nil

      @head = (@head + 1) & @max_mask
      return object
    end
  end
end
