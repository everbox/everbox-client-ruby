require 'logger'

module EverboxClient
  autoload :PathEntry, 'everbox_client/models/path_entry'
  autoload :User, 'everbox_client/models/user'
  autoload :Account, 'everbox_client/models/account'

  def self.logger
    @logger ||= Logger.new(STDERR)
  end
end
