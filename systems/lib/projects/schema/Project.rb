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
      return "> ".bold.red + "The project is already completed." unless self.completed == false
      return "> ".bold.red + "There's no such task associated with this project." unless task = self.tasks.where(:name => Regexp.new("(?i)#{task_name}")).first
      
      effort_last = self.efforts.where(:character => dbref).desc(:created_at).first
      unless (effort_last.nil? || DateTime.now > effort_last.created_at + self.interval.hours) then
        return "> ".bold.red + "You must wait #{((effort_last.created_at + self.interval.hours) - DateTime.now).to_timestring.bold.yellow} before you can work on this project again."
      end
      
      result = rand(5) - 2 
      effort = self.efforts.create!(:character => dbref, :success => result)
      task.current = (task.current + result >= task.goal ? task.goal : task.current + result)
      task.save
      p "You do some work on the '#{task.name}' phase of the #{self.title} project and #{result > 0 ? 'succeed!'.bold.green : 'fail!'.bold.red}"
      
      if (task.current == task.goal) then
        completed = true
        
        self.tasks.each do |i|
          if (task.current < task.goal) then
            completed = false
            break
          end
        end
        
        if (completed == true) then
          self.completed = true
          self.save
          p "You've completed the project!"
        end
      end
      
      return self
    end
  end
  
end
