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
    
    def inspect
      ret = titlebar("Project Board: #{self.title}") + "\n"
      ret << 'Phase'.ljust(29).yellow + 'Skill'.ljust(21).yellow + 'Diff'.ljust(14).yellow + 'Progress' + "\n"
      self.tasks.each do |task|
        ret << task.name.ljust(29) + task.skill.ljust(21) + task.difficulty.to_s.ljust(14) + "#{task.current} of #{task.goal}" + "\n"
      end
      
      ret << footerbar
    end
  end
  
end
