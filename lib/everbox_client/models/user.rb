require 'everbox_client'

module EverboxClient
  class User
    def initialize(data)
      @data = data
    end

    def to_s
      res = ""
      res << "username: #{@data["username"]}\n"
      res << "email: #{@data["email"]}\n"
      res << "\n"
      unless @data["accounts"].empty?
        res << "Accounts:\n"
        @data["accounts"].each do |account|
          res << "  " << Account.new(account).to_s << "\n"
        end
      end
      res
    end
  end
end
