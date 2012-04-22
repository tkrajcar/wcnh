require 'wcnh'

module Projects
  class Effort
    include Mongoid::Document
    include Mongoid::Timestamps::Created
    
    field :character, type: String
    field :success, type: Integer
    
    belongs_to :project, :class_name => "Projects::Project"
  end
end
