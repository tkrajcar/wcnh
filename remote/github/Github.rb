require 'pennmush-json'
require 'github-v3-api'

module Github
  PennJSON::register_object(self)

  @api = GitHubV3API.new('52364226a675c6090b6551c609fc052d6e74c7ba')
  @user = "tkrajcar"
  @repo = "wcnh_softcode"

  def self.pj_issues_list(*args)
    @api.issues.list({:user => @user, :repo => @repo}).collect{|x| x.to_mush}.join('|')
  end
end

class GitHubV3API::Issue
  def to_mush
    ret = [self.number, self.title, self.body, self.created_at, self.updated_at, self.user["login"]]
    begin
      ret.push self.assignee["login"]
    rescue NameError # no assignee
      ret.push "" 
    end
    ret.join('`')
  end
end

