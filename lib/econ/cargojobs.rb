require 'wcnh'

module Econ
  def self.cargojob_list
    ret = titlebar("Cargo Job Listing") + "\n"
    economics_skill = R.u("#112/fn.get.skill",R["enactor"],"economics").to_i
    streetwise_skill = R.u("#112/fn.get.skill",R["enactor"],"streetwise").to_i
    available_jobs = CargoJob.where(claimed: false).where(:expires.gte => DateTime.now).where(:visibility.lte => [economics_skill, streetwise_skill].max).asc(:expires)
    ret << "##### #{'Routing'.ljust(18)} Size   Value  Expires Manifest".cyan + "\n"
    ret << " There don't seem to be any jobs available to you.\n" if available_jobs.count == 0
    available_jobs.each do |job|
      ret << job.to_mush
      ret << "\n"
    end
    if CargoJob.open_and_claimed_by(R["enactor"]).count > 0
      ret << middlebar("YOUR CLAIMED AND NOT YET LOADED JOBS") + "\n"
      CargoJob.open_and_claimed_by(R["enactor"]).each do |job|
        ret << job.to_mush
        ret << "\n"
      end
    end
    if CargoJob.loaded_and_claimed_by(R["enactor"]).count > 0
      ret << middlebar("YOUR LOADED JOBS") + "\n"
      CargoJob.loaded_and_claimed_by(R["enactor"]).each do |job|
        ret << job.to_mush
        ret << "\n"
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
    return "> ".bold.green + "Your economics skill only allows you to have #{economics_skill} claim#{economics_skill == 1 ? 's' : ''} active at once." if CargoJob.open_and_claimed_by(R["enactor"]).count >= economics_skill
    job.claimed = true
    job.claimed_by = R["enactor"]
    job.save
    Logs.log_syslog("CARGOJOBCLAIM", "#{R.penn_name(R["enactor"])} claimed job #{job.number} (#{job._id}).")
    "> ".bold.green + "You claim job #{job.number.to_s.bold}."
  end
  

  def self.cargojob_load(job,shipname)
    job = CargoJob.where(number: job).first
    return "> ".bold.green + "That doesn't seem to be a valid job." if job.nil?
    return "> ".bold.green + "You don't have that job claimed!" unless job.claimed_by == R["enactor"]
    return "> ".bold.green + "That job has expired." if job.expires < DateTime.now
    return "> ".bold.green + "That job has already been loaded!" if job.is_loaded

    port_location = R.xget(job.source.space_object,"DATA.LANDING")
    ship = R.locate(port_location,shipname,"TF*")

    return "> ".bold.green + "There doesn't seem to be a ship by that name at #{job.source.name.bold}." if ship == "#-1"
    return "> ".bold.green + "You're not on the crew list for the #{R.penn_name(ship).bold}." unless R.u("#25/SPACESYS.FN","canboard",ship,R["enactor"]).to_bool

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
    return "> ".bold.green + "You're not on the crew list for the ship that job is on." unless R.u("#25/SPACESYS.FN","canboard",job.loaded_on,R["enactor"]).to_bool
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
end
