module EverboxClient
  class Exception < RuntimeError; end

  class UnknownResponseException < Exception
    def initialize(response)
      super("unknown response code: #{response.code}\n#{response.body}")
    end
  end
end
