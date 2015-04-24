require 'wcnh'
module Web
  R = PennJSON::Remote

  def self.register(password)
    email = R.xget(R["enactor"],"registered_email")
    return ">".bold + " You don't seem to have a registered email address. Contact an admin to get this resolved." unless !email.nil? && !email.empty?
    result = WebAPIClient.register(email,password,R["enactor"],R.penn_name(R["enactor"]))
    return ">".bold + " There was a problem: #{result["message"]}" unless result["success"]
    return ">".bold + " Registration completed! You can now login to the website using your registered email, #{email.bold}, and password #{password.bold}."
  end
end
