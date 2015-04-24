require 'wcnh'

module Projects
  
  class Task
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :name, type: String
    field :skill, type: String
    field :difficulty, type: Integer, :default => 1
    field :current, type: Integer, :default => 0
    field :goal, type: Integer, :default => 0
    
    embedded_in :project, :class_name => "Projects::Project"
    
    validates_presence_of :name, message: "The task must have a name."
    validates_presence_of :skill, message: "The task must have a skill requirement."
    
    validates_numericality_of :difficulty, greater_than: 0, message: "Difficulty must be an integer >0."
    validates_numericality_of :goal, greater_than: 0, message: "Goal must be an integer >0."  
  end
  
end
