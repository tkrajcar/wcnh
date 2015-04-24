require 'wcnh'

module BBoard
  
  class Category
    include Mongoid::Document
    
    field :num, type: Integer, :default => lambda {Counters.next("BBCategory")}
    field :name, type: String
    field :ansi, type: String, :default => "n" # Ansi string for colorized boards in-game
    field :permission_type, type: String 
    field :permission_value, type: String
    field :anonymous, type: String, :default => nil
    field :timeout, type: Integer, :default => nil # Default timeout in days for posts
    
    has_many :posts, :class_name => "BBoard::Post"
    has_many :subscriptions, :class_name => "BBoard::Subscription"
    
    validates_uniqueness_of :num, message: "Board number is already being used."
    validates_numericality_of :num, greater_than: 0, message: "Board number must be greater than 0."
    
    validates_uniqueness_of :name, case_sensitive: false, message: "Category name must be unique."
    validates_presence_of :name, message: "Category name cannot be blank."
    
    validates_format_of :ansi, with: /^([hn]|)([gybmcw]|)$/, message: "Invalid ansi code."

    validates_numericality_of :timeout, allow_nil: true, greater_than: 0, message: "Timeout must be an integer number of days."
    
    def canread?(dbref)
      return true if self.permission_type == "announce"
      return self.canwrite?(dbref)
    end
    
    def canwrite?(dbref)
      return true if self.permission_type.nil?
      return true if R.orflags(dbref, "Wr").to_bool
      if self.permission_type == 'faction'
        return R.u("#114/fn.ismember", self.permission_value, dbref).to_bool
      end
      if self.permission_type == 'guide'
        R.hasflag(dbref, "guide").to_bool
      end
      return false
    end
    
    def cleanup
      return nil if self.timeout.nil?
      count = 0
      self.posts.where(:created_at.lt => DateTime.now - self.timeout.days, :sticky => false).each do |i|
        i.delete
        i.save
        count += 1
      end
      p "#{count} posts timed out."
      return count
    end
  end
  
end
