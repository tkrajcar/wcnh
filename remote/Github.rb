require 'lib-github'
require 'pennmush-json'

module Github
  PennJSON::register_object(self)
  R = PennJSON::Remote

  def self.pj_issues_list(*args)
    R.nspemit(R["enactor"],"[titlebar(wcnh_softcode Issues List)]")
    R.nspemit(R["enactor"],"%b%b### [ljust(Title,40)] Created  Updated")
    self.issues_list.each { |issue|
      created = Time.parse(issue.created_at).localtime
      updated = Time.parse(issue.updated_at).localtime
      R.nspemit(R["enactor"],"%b%b#{issue.number.to_s.rjust(3)} #{issue.title[0..39]} #{created.strftime("%D").ljust(8)} #{updated.strftime("%D")}")
    }
    R.nspemit(R["enactor"],"[footerbar()]")
  end
end


