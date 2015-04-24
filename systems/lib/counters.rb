require "wcnh"

# Handy module for working with Mongo-backed numeric sequences.
module Counters

  # return the next value of a counter and increment the datastore.
  # this is the method you want to call almost all the time.
  def self.next(name)
    c = Counter.find_or_create_by(:name => name)
    c.inc(:value,1)
  end

  # get the next value of a counter.
  # does not increment the datastore.
  def self.peek(name)
    c = Counter.find_or_create_by(:name => name)
    c.value
  end

  class Counter
    include Mongoid::Document
    field :name, :type => String
    index :name, :unique => true
    field :value, :type => Integer, :default => 0
  end
end