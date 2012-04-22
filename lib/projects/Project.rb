require 'wcnh'

module Projects
  
  class Project
    include Mongoid::Document
    
    field :title, type: String
    field :details, type: String
    field :managers, type: Array
    field :members, type: Array
    field :public, type: Boolean, :default => false
    
    embeds_many :tasks, :class_name => "Projects::Task"
    embeds_many :efforts, :class_name => "Projects::Effort"
  end
  
end
