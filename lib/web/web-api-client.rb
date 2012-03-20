require 'httparty'

class WebAPIClient
  include ::HTTParty
  base_uri 'http://wcmush.com/api'

  def self.register(email, password, current_dbref, current_name)
    begin
      result = get("/user_register", query: {email: email, password: password, current_dbref: current_dbref, current_name: current_name})
      if result.response.code != "200" 
        return {:success => false, :message => "HTTP error code #{result.response.code} received"}
      end
      return result.parsed_response
    rescue Exception => e
      return {:success => false, :message => "Exception: #{e.message}"}
    end
  end
end
