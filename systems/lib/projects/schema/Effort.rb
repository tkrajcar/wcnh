require 'wcnh'

module Projects
  class Effort
    include Mongoid::Document
    include Mongoid::Timestamps::Created
    
    field :character, type: String
    field :success, type: Integer
    
    embedded_in :project, :class_name => "Projects::Project"
  end
end
