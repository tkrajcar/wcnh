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
      ret << middlebar("YOUR CLAIMED JOBS") + "\n"
      CargoJob.open_and_claimed_by(R["enactor"]).each do |job|
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
  end
end
