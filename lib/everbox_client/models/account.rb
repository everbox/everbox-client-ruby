module EverboxClient
  class Account
    def initialize(data)
      @data = data
    end

    def google?
      @data["type"] == 'google'
    end

    def sdo?
      @data["type"] == 'sdo'
    end

    def to_s
      if google?
        "Google Account: #{@data["email"]}"
      elsif sdo?
        "SDO Account: #{@data["name"]}"
      else
        "Unknown Account Type: #{@data["type"]}"
      end
    end
  end
end
