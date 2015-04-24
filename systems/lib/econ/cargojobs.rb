require 'wcnh'

module Econ
  def self.cargojob_list
    ret = titlebar("Cargo Job Listing") + "\n"
    economics_skill = R.u("#112/fn.get.skill",R["enactor"],"economics").to_i
    streetwise_skill = R.u("#112/fn.get.skill",R["enactor"],"streetwise").to_i
    available_jobs = CargoJob.where(claimed: false).where(:expires.gte => DateTime.now).where(publicity: nil).where(:visibility.lte => [economics_skill, streetwise_skill].max).asc(:expires)
    ret << "##### #{'Routing'.ljust(21)} Size   Value  Expires Manifest".cyan + "\n"
    ret << " There don't seem to be any jobs available to you.\n" if available_jobs.count == 0
    available_jobs.each do |job|
      ret << job.to_mush
    end
    player_factions = (R.u("#25/faction.fn","list.memberof",R["enactor"]) || "").split(' ')
    private_jobs = CargoJob.where(claimed: false).where(:expires.gte => DateTime.now)
    if R.orflags(R["enactor"],"Wr").to_bool
      private_jobs = private_jobs.where(:publicity.ne => nil)
    else
      private_jobs = private_jobs.any_in(:publicity => player_factions)
    end
    private_jobs = private_jobs.asc(:expires)
    if private_jobs.count > 0
      ret << middlebar("UNCLAIMED PRIVATE JOBS YOU CAN SEE") + "\n"
      private_jobs.each do |job|
        ret << job.to_mush
      end
    end
    if CargoJob.unloaded_and_claimed_by(R["enactor"]).count > 0
      ret << middlebar("YOUR CLAIMED AND NOT YET LOADED JOBS") + "\n"
      CargoJob.unloaded_and_claimed_by(R["enactor"]).each do |job|
        ret << job.to_mush
        ret << "      Assigned to #{R.penn_name(job.assigned_to).cyan.bold}.\n" unless job.assigned_to.nil?
      end
    end
    if CargoJob.unloaded_and_assigned_to(R["enactor"]).count > 0
      ret << middlebar("YOUR ASSIGNED AND NOT YET LOADED JOBS") + "\n"
      CargoJob.unloaded_and_assigned_to(R["enactor"]).each do |job|
        ret << job.to_mush
      end
    end
    if CargoJob.loaded_and_claimed_by(R["enactor"]).count > 0
      ret << middlebar("YOUR CLAIMED AND LOADED JOBS") + "\n"
      CargoJob.loaded_and_claimed_by(R["enactor"]).each do |job|
        ret << job.to_mush
        ret << "      Assigned to #{R.penn_name(job.assigned_to).cyan.bold}.\n" unless job.assigned_to.nil?
      end
    end
    if CargoJob.loaded_and_assigned_to(R["enactor"]).count > 0
      ret << middlebar("YOUR ASSIGNED AND LOADED JOBS") + "\n"
      CargoJob.loaded_and_assigned_to(R["enactor"]).each do |job|
        ret << job.to_mush
      end
    end
    ret << footerbar()
  end

  def self.cargojob_claim(job)
    economics_skill = R.u("#112/fn.get.skill",R["enactor"],"economics").to_i
    streetwise_skill = R.u("#112/fn.get.skill",R["enactor"],"streetwise").to_i

    job = CargoJob.where(number: job).first
    return "> ".bold.green + "That doesn't seem to be a valid job." if job.nil?
    return "> ".bold.green + "Your economics & streetwise skills don't allow you to claim that job." if job.visibility > [economics_skill, streetwise_skill].max
    return "> ".bold.green + "That job is already claimed!" if job.claimed 
    return "> ".bold.green + "That job has expired." if job.expires < DateTime.now
    return "> ".bold.green + "Your economics skill only allows you to have #{economics_skill} claim#{economics_skill > 1 ? 's' : ''} active at once." if CargoJob.open_and_claimed_by(R["enactor"]).count >= economics_skill
    if !job.publicity.nil?
      player_factions = (R.u("#25/faction.fn","list.memberof",R["enactor"]) || "").split(' ')
      return "> ".bold.green + "That cargo job is not public." unless player_factions.include?(job.publicity)
    end
    job.claimed = true
    job.claimed_by = R["enactor"]
    job.save
    Logs.log_syslog("CARGOJOBCLAIM", "#{R.penn_name(R["enactor"])} claimed job #{job.number} (#{job._id}).")
    "> ".bold.green + "You claim job #{job.number.to_s.bold}."
  end

  def self.cargojob_assign(job,person)
    victim = R.pmatch(person)

    job = CargoJob.where(number: job).first
    return "> ".bold.green + "That doesn't seem to be a valid job." if job.nil?
    return "> ".bold.green + "That's not a valid player!" if victim == "#-1"
    return "> ".bold.green + "You can't assign jobs to yourself. Use cargo/unassign." if victim == R["enactor"]
    return "> ".bold.green + "You don't have that job claimed!" unless job.claimed_by == R["enactor"]
    return "> ".bold.green + "That job has already been loaded - it's too late to assign it." if job.is_loaded
    return "> ".bold.green + "That job has expired." if job.expires < DateTime.now
    job.assigned_to = victim
    job.save
    Logs.log_syslog("CARGOJOBASSIGN", "#{R.penn_name(R["enactor"])} assigned job #{job.number} (#{job._id}) to #{R.penn_name(victim)}.")
    R.nspemit(victim,"> ".bold.green + "#{R.penn_name(R["enactor"]).bold} has assigned cargo job #{job.number.to_s.bold.yellow} to you.")
    "> ".bold.green + "You assign job #{job.number.to_s.bold} to #{R.penn_name(victim).bold.yellow}."
  end

  def self.cargojob_unassign(job)
    job = CargoJob.where(number: job).first
    return "> ".bold.green + "That doesn't seem to be a valid job." if job.nil?
    return "> ".bold.green + "You don't have that job claimed!" unless job.claimed_by == R["enactor"]
    return "> ".bold.green + "That job isn't assigned!" if job.assigned_to.nil?
    return "> ".bold.green + "That job has already been loaded - it's too late to unassign it." if job.is_loaded
    return "> ".bold.green + "That job has expired." if job.expires < DateTime.now
    R.nspemit(job.assigned_to,"> ".bold.green + "#{R.penn_name(R["enactor"]).bold} has unassigned cargo job #{job.number.to_s.bold.yellow} from you.")
    job.assigned_to = nil
    job.save
    Logs.log_syslog("CARGOJOBUNASSIGN", "#{R.penn_name(R["enactor"])} unassigned job #{job.number} (#{job._id})}.")
    "> ".bold.green + "You unassign job #{job.number.to_s.bold}."
  end


  def self.cargojob_unclaim(job)
    job = CargoJob.where(number: job).first
    return "> ".bold.green + "That doesn't seem to be a valid job." if job.nil?
    return "> ".bold.green + "That job is not claimed by you!" unless job.claimed_by == R["enactor"]
    return "> ".bold.green + "That job has expired." if job.expires < DateTime.now
    return "> ".bold.green + "You've already loaded that job, it's too late to unclaim it." if job.is_loaded
    
    job.assigned_to = nil
    job.claimed = false
    job.claimed_by = nil
    job.save
    Logs.log_syslog("CARGOJOBUNCLAIM", "#{R.penn_name(R["enactor"])} unclaimed job #{job.number} (#{job._id}).")
    "> ".bold.green + "You unclaim job #{job.number.to_s.bold}."
  end

  def self.cargojob_load(job,shipname)
    job = CargoJob.where(number: job).first
    return "> ".bold.green + "That doesn't seem to be a valid job." if job.nil?
    if job.assigned_to.nil?
      return "> ".bold.green + "You don't have that job claimed!" unless job.claimed_by == R["enactor"]
    else
      return "> ".bold.green + "That job isn't assigned to you!" unless job.assigned_to = R["enactor"]
    end
    return "> ".bold.green + "That job has expired." if job.expires < DateTime.now
    return "> ".bold.green + "That job has already been loaded!" if job.is_loaded

    port_location = R.xget(job.source.space_object,"DATA.LANDING")
    ship = R.locate(port_location,shipname,"TF*")

    return "> ".bold.green + "There doesn't seem to be a ship by that name at #{job.source.name.bold}." if ship == "#-1"
    return "> ".bold.green + "You're not on the crew list for the #{R.penn_name(ship).bold}." unless R.u("#25/SPACESYS.FN","iscrew",ship,R["enactor"]).to_bool

    # check remaining cargo capacity
    cur = R.xget(ship,"SPACE`CARGO`CUR").to_i
    max = R.xget(ship,"SPACE`CARGO`MAX").to_i
    return "> ".bold.green + "That ship only has #{max - cur} m3 of remaining cargo space." if (cur + job.size) > max

    onboard = (R.xget(ship,"SPACE`CARGO`ONBOARD") || "").split(' ')
    onboard << job.number.to_s
    R.attrib_set("#{ship}/SPACE`CARGO`ONBOARD",onboard.join(' '))
    R.attrib_set("#{ship}/SPACE`CARGO`CUR",(cur + job.size).to_s)

    job.is_loaded = true
    job.loaded_on = ship
    job.save
    Logs.log_syslog("CARGOJOBLOAD", "#{R.penn_name(R["enactor"])} loaded job #{job.number} into #{R.penn_name(ship)}(#{ship}).")

    R.remit(port_location,"Ground crews begin loading #{job.size} m3 of #{job.grade_text} #{job.commodity.name} into the #{R.penn_name(ship).bold}.")
    R.nspemit(job.claimed_by,"> ".bold.green + "Job #{job.number.to_s.bold} has been loaded into the #{R.penn_name(ship).bold.yellow}.") unless job.assigned_to.nil?
    return "> ".bold.green + "Loading #{job.size} m3 of #{job.grade_text} #{job.commodity.name} into the #{R.penn_name(ship).bold}."
  end

  def self.cargojob_manifest(ship)
    ret = titlebar("Cargo Manifest: #{R.penn_name(ship)}") + "\n"
    jobnumbers = R.xget(ship,"SPACE`CARGO`ONBOARD") || ""
    ret << "##### #{'Routing'.ljust(18)} Size   Value  Expires Manifest".cyan + "\n" if jobnumbers.split(' ').length > 0
    jobnumbers.split(' ').each do |jobnumber|
      job = CargoJob.where(number: jobnumber).first
      ret << job.to_mush
      ret << "\n"
    end
    cur = R.xget(ship,"SPACE`CARGO`CUR").to_i
    max = R.xget(ship,"SPACE`CARGO`MAX").to_i
    ret << "      #{cur.to_s.bold.yellow} m3 of cargo on board. #{(max - cur).to_s.bold.yellow} m3 of space remaining.\n"
    ret << footerbar()
  end


  def self.cargojob_deliver(job)
    job = CargoJob.where(number: job).first
    return "> ".bold.green + "That doesn't seem to be a valid job." if job.nil?
    return "> ".bold.green + "That job hasn't been loaded yet!" unless job.is_loaded
    return "> ".bold.green + "That job has already been delivered!" if job.completed
    return "> ".bold.green + "You're not on the crew list for the ship that job is on." unless R.u("#25/SPACESYS.FN","iscrew",job.loaded_on,R["enactor"]).to_bool
    port_location = R.xget(job.destination.space_object,"DATA.LANDING")
    return "> ".bold.green + "The ship that job's on isn't at #{job.destination.name.bold}." unless R.penn_loc(job.loaded_on) == port_location
    
    # handle expirations
    if job.expires < DateTime.now
      R.nspemit(R["enactor"],"> ".bold.green + "Unloading job #{job.number}. Sadly, the job expired, so it's worthless now.")
      R.nspemit(job.claimed_by,"> ".bold.green + "Your claimed job #{job.number} was delivered, but the job expired.") unless job.claimed_by == R["enactor"]
      Logs.log_syslog("CARGOJOBDELIVER", "#{R.penn_name(R["enactor"])} delivered job #{job.number}, but it expired.")
    else
      if R["enactor"] == job.claimed_by
        R.nspemit(R["enactor"],"> ".bold.green + "Unloading job #{job.number}. #{job.price} credits paid.")
        job.delivered = true
      else
        R.nspemit(R["enactor"],"> ".bold.green + "Unloading job #{job.number}. #{job.price} credits paid to #{R.penn_name(job.claimed_by)}.")
        R.nspemit(job.claimed_by,"> ".bold.green + "Your claimed #{job.number} has been delivered. #{job.price} credits paid.")
      end
      Econ.grant(job.claimed_by,job.price)
      Logs.log_syslog("CARGOJOBDELIVER", "#{R.penn_name(R["enactor"])} delivered job #{job.number}. #{job.price} credits paid.")
    end
    R.remit(port_location,"Ground crews begin unloading #{job.size} m3 of #{job.grade_text} #{job.commodity.name} from the #{R.penn_name(job.loaded_on).bold}.")
    # remove from ONBOARD
    onboard = (R.xget(job.loaded_on,"SPACE`CARGO`ONBOARD") || "").split(' ')
    onboard.delete(job.number.to_s)
    R.attrib_set("#{job.loaded_on}/SPACE`CARGO`ONBOARD",onboard.join(' '))
  
    cur = R.xget(job.loaded_on,"SPACE`CARGO`CUR").to_i
    R.attrib_set("#{job.loaded_on}/SPACE`CARGO`CUR",(cur - job.size).to_s)

    job.completed = true
    job.save
    ""
  end

  def self.cargojob_transfer(job,to_ship)
    job = CargoJob.where(number: job).first
    return "> ".bold.green + "That doesn't seem to be a valid job." if job.nil?
    return "> ".bold.green + "That job hasn't been loaded yet!" unless job.is_loaded
    return "> ".bold.green + "That job has already been delivered!" if job.completed
    return "> ".bold.green + "You're not on the crew list for the ship that job is on." unless R.u("#25/SPACESYS.FN","iscrew",job.loaded_on,R["enactor"]).to_bool
    return "> ".bold.green + "The ship that job is on isn't landed!" unless R.hasattrval(job.loaded_on,"DATA.DOCKED").to_bool

    port_location = R.loc(job.loaded_on)
    ship = R.locate(port_location,to_ship,"TF*")

    return "> ".bold.green + "There doesn't seem to be a ship by that name nearby." if ship == "#-1"
    return "> ".bold.green + "The job is already on that ship!" if ship == job.loaded_on
    return "> ".bold.green + "You're not on the crew list for the #{R.penn_name(ship).bold}." unless R.u("#25/SPACESYS.FN","iscrew",ship,R["enactor"]).to_bool

    # check remaining cargo capacity
    cur = R.xget(ship,"SPACE`CARGO`CUR").to_i
    max = R.xget(ship,"SPACE`CARGO`MAX").to_i
    return "> ".bold.green + "That ship only has #{max - cur} m3 of remaining cargo space." if (cur + job.size) > max

    # load job on destination
    onboard = (R.xget(ship,"SPACE`CARGO`ONBOARD") || "").split(' ')
    onboard << job.number.to_s
    R.attrib_set("#{ship}/SPACE`CARGO`ONBOARD",onboard.join(' '))
    R.attrib_set("#{ship}/SPACE`CARGO`CUR",(cur + job.size).to_s)

    # remove job from source
    onboard = (R.xget(job.loaded_on,"SPACE`CARGO`ONBOARD") || "").split(' ')
    onboard.delete(job.number.to_s)
    R.attrib_set("#{job.loaded_on}/SPACE`CARGO`ONBOARD",onboard.join(' '))

    cur = R.xget(job.loaded_on,"SPACE`CARGO`CUR").to_i
    R.attrib_set("#{job.loaded_on}/SPACE`CARGO`CUR",(cur - job.size).to_s)

    Logs.log_syslog("CARGOJOBTRANSFER", "#{R.penn_name(R["enactor"])} transferred job #{job.number} from #{R.penn_name(job.loaded_on)} to #{R.penn_name(ship)}(#{ship}).")

    # TODO: Better notification

    R.remit(port_location,"Ground crews begin unloading #{job.size} m3 of #{job.grade_text} #{job.commodity.name} from the #{R.penn_name(job.loaded_on).bold}, and loading it into the #{R.penn_name(ship).bold}.")
    R.nspemit(job.claimed_by,"> ".bold.green + "Job #{job.number.to_s.bold} has been transferred to the #{R.penn_name(ship).bold.yellow}.") unless job.claimed_by == R["enactor"]
    R.nspemit(job.assigned_to,"> ".bold.green + "Job #{job.number.to_s.bold} has been transferred to the #{R.penn_name(ship).bold.yellow}.") unless job.assigned_to == R["enactor"] || job.assigned_to.nil?

    job.loaded_on = ship
    job.save
    return "> ".bold.green + "Transferring job #{job.number.to_s.bold} to the #{R.penn_name(ship).bold.yellow}."
  end

  def self.cargojob_generate(user=nil)
    available_job_count = CargoJob.where(claimed: false).where(:expires.gte => DateTime.now).count
    #Logs.log_syslog("CARGOJOBGENERATOR","Running cargo generator. #{available_job_count.to_s} jobs available.")
    if available_job_count <= 10 && user.nil?
      self.generate_one_job
      self.generate_one_job
      self.generate_one_job
    elsif available_job_count <= 25 && user.nil?
      self.generate_one_job
      self.generate_one_job
    else
      self.generate_one_job
    end
    ""
  end

  def self.generate_one_job
    j = CargoJob.generate
    Logs.log_syslog("CARGOJOBGENERATE","Cargo job #{j.number.to_s} generated.")
  end
  
  def self.cargojob_edit(user, num, opt, val)
    options = [:grade, :expires, :size, :price, :visibility, :source, :destination, :commodity, :publicity]
    
    return "> ".bold.red + "No such cargo job." unless job = CargoJob.where(:number => num).first
    return "> ".bold.red + "Invalid option.  Valid options are: " + options.itemize unless options.include?(opt.to_sym)
    
    case opt.to_sym
    when :expires
      time_num = val.split(' ')[0].to_i
      time_type = val.split(' ')[1]
      unless (time_num > 0 && (time_type == "hours" || time_type == "days")) then
        return "> ".bold.red + "Time must be in the form of: <num> [hours|days].  I.e., '5 hours' or '10 days'."
      else
        val = (time_type == "hours" ? DateTime.now + time_num.hours : DateTime.now + time_num.days)
      end
    when :source, :destination
      locations = []
      Location.all.each { |i| locations << i.name }
      return "> ".bold.red + "Invalid location.  Valid locations are: " + locations.itemize unless val = Location.where(:lowercase_name => val.downcase).first
    when :commodity
      commodities = []
      Commodity.all.each { |i| commodities << i.name }
      return "> ".bold.red + "Invalid commodity.  Valid commodities are: " + commodities.itemize unless val = Commodity.where(:lowercase_name => val.downcase).first
    when :publicity
      val = nil if val == ""
    end
    
    job.update_attributes(opt.to_sym => val)
    return "> ".bold.red + job.errors[opt].join(" ") unless job.valid?
    
    job.save
    return "> ".bold.green + "'#{opt.capitalize}' option on job '#{job.number}' updated."
  end
end
