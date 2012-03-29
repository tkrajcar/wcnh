require 'wcnh'

module BBoard
  
  class User
    include Mongoid::Document
    
    identity :type => String
    # Reserve the user class instead of just pulling the dbref on the fly in case we want a place to store
    # global bboard user settings.
    
    has_many :subscriptions, :class_name => "BBoard::Subscription"
  end
  
  class Category
    include Mongoid::Document
    
    field :name, type: String
    field :ansi, type: String, :default => "n" # Ansi string for colorized boards in-game
    field :permission_type, type: String 
    field :permission_value, type: String
    field :anonymous, type: Boolean, :default => false
    field :timeout, type: Integer, :default => nil # Default timeout in days for posts
    
    has_many :posts, :class_name => "BBoard::Post"
    has_many :subscriptions, :class_name => "BBoard::Subscription"
    
    def can_read?(dbref)
      return true if self.permission_type == "announce"
      return self.can_write?(dbref)
    end
    
    def can_write?(dbref)
      return true if self.permission_type.nil?
      return true if R.orflags(dbref, "Wr").to_bool
      return false
    end
    
    def cleanup
      return nil if self.timeout.nil?
      range = (DateTime.now - self.timeout.days)..DateTime.now
      count = 0
      self.posts.where(created_at: range).each do |i|
        i.old = true
        count += 1
      end
      p "#{count} posts timed out."
    end
  end
  
  class Post
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :sticky, type: Boolean, :default => false
    field :author, type: String
    field :title, type: String
    field :body, type: String
    field :parent_id , type: String # Posts that are threads belong to a parent post.
    field :old, type: Boolean, :default => false # Posts that timeout are invisible but archived
    
    belongs_to :category, :class_name => "BBoard::Category"
  end
  
  class Subscription
    include Mongoid::Document
    
    field :read_posts, type: Array
    
    belongs_to :user, :class_name => "BBoard::User"
    belongs_to :category, :class_name => "BBoard::Category"
  end
  
end
