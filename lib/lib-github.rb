require 'wcnh'
require 'github-v3-api'

module Github
  @api = GitHubV3API.new('52364226a675c6090b6551c609fc052d6e74c7ba')
  @user = "tkrajcar"
  @repo = "wcnh_softcode"

  def self.issues_list
    @api.issues.list({:user => @user, :repo => @repo})
  end
end
