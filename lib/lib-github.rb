require 'wcnh'
require 'github-v3-api'

module Github

  @api = GitHubV3API.new('52364226a675c6090b6551c609fc052d6e74c7ba')
  @user = "tkrajcar"
  @repo = "wcnh_softcode"

  def self.issues_list
    ret = ""
    ret.ccl "[titlebar(wcnh_softcode Issues List)]"

    ret.ccl "%b%b### [ljust(Title,40)] Created  Updated"
    @api.issues.list({:user => @user, :repo => @repo}).each { |issue|
      created = Time.parse(issue.created_at).localtime
      updated = Time.parse(issue.updated_at).localtime
      ret.ccl "%b%b#{issue.number.to_s.rjust(3)} #{issue.title[0..39]} #{created.strftime("%D").ljust(8)} #{updated.strftime("%D")}"
    }

    ret.ccl "[footerbar()]"
  end
end
