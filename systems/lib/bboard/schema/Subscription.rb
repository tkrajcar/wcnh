require 'wcnh'

module BBoard
  
  class Subscription
    include Mongoid::Document
    
    field :read_posts, type: Array, :default => []
    
    belongs_to :user, :class_name => "BBoard::User"
    belongs_to :category, :class_name => "BBoard::Category"

    def unread_posts
      posts = []
      self.category.posts.where(:parent_id => nil).asc(:created_at).each do |post|
        posts << post if !self.read_posts.include?(post.id)
      end
      return posts
    end
    
    def unread_replies
      replies = {}

      self.category.posts.each do |post|
        post_replies = []

        self.category.posts.where(:parent_id => post.id).asc(:created_at).each do |reply|
          post_replies << reply if !self.read_posts.include?(reply.id)
        end
      
        replies[post] = post_replies if post_replies.length > 0
      end

      return replies
    end
  end
  
end
