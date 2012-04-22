require 'wcnh'

module Projects
  
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :name, type: String
    field :skill, type: String
    field :difficulty, type: Integer
    field :current, type: Integer
    field :goal, type: Integer  
    
    belongs_to :project, :class_name => "Projects::Project"
  end
  
end
