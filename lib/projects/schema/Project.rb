require 'wcnh'

module Projects
  
  class Project
    include Mongoid::Document
    
    field :title, type: String
    field :details, type: String
    field :managers, type: Array, :default => []
    field :members, type: Array, :default => []
    field :public, type: Boolean, :default => false
    field :completed, type: Boolean, :default => false
    field :interval, type: Integer, :default => 3 # Number of hours between eligible work periods
    
    embeds_many :tasks, :class_name => "Projects::Task"
    embeds_many :efforts, :class_name => "Projects::Effort"
    
    validates_presence_of :title, message: "The project must have a title."
    
    def inspect
      ret = titlebar("Project Board: #{self.title}") + "\n"
      ret << 'Phase'.ljust(29).yellow + 'Skill'.ljust(21).yellow + 'Diff'.ljust(14).yellow + 'Progress' + "\n"
      self.tasks.each do |task|
        ret << task.name.ljust(29) + task.skill.ljust(21) + task.difficulty.to_s.ljust(14) + "#{task.current} of #{task.goal}" + "\n"
      end
      
      ret << footerbar
    end
    
    def work(dbref, task_name)
      return "> ".bold.red + "You aren't a member of that project." unless (self.managers + self.members).include?(dbref)
      return "> ".bold.red + "There's no such task associated with this project." unless task = self.tasks.where(:name => Regexp.new("(?i)#{task_name}"))
      
      effort = self.efforts.where(:character => dbref).desc(:created_at).first
      unless (effort.nil? || DateTime.now > effort.created_at + self.interval) then
        return "> ".bold.red + "You must wait until #{effort.created_at + self.interval} before doing additional work on this project."
      end
      
      p "Do work."
      return
    end
  end
  
end
