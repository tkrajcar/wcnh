module Mongoid
  module Document
    def self.included(base)
      $mongoid_classes ||= []
      $mongoid_classes << base
    end
  end
end

