require 'wcnh'

module Econ
  def self.cargojob_list
    ret = titlebar("Cargo Job Listing") + "\n"
    economics_skill = R.u("#112/fn.get.skill",R["enactor"],"economics")
    streetwise_skill = R.u("#112/fn.get.skill",R["enactor"],"streetwise")
    available_jobs = CargoJob.where(claimed: false).where(:expires.gte => DateTime.now).where(:visibility.lte => [economics_skill, streetwise_skill].max).asc(:expires)
    ret << "##### #{'Routing'.ljust(18)} Size   Value  Expires Manifest".cyan + "\n"
    ret << " There don't seem to be any jobs available to you. " if available_jobs.count == 0
    available_jobs.each do |job|
      ret << job.number.to_s.rjust(5).bold.yellow
      ret << " "
      ret << "#{job.source.name}-#{job.destination.name}".ljust(18)
      ret << " "
      ret << job.size.to_s.rjust(4)
      ret << credit_format(job.price).to_s.rjust(8).bold.yellow
      ret << " "
      expires_in = job.expires.to_time - DateTime.now
      mm, ss = expires_in.divmod(60)            #=> [4515, 21]
      hh, mm = mm.divmod(60)           #=> [75, 15]
      dd, hh = hh.divmod(24)           #=> [3, 3]
      if dd > 0
        ret << "#{dd}d "
      else
        ret << "   "
      end
      ret << "#{hh.to_s.rjust(2,'0')}:#{mm.to_s.rjust(2,'0')}"

      ret << " "
      ret << job.grade_text
      ret << " "
      ret << job.commodity.name
      ret << "\n"

    end
    ret << footerbar()
  end
end
