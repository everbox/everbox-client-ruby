require 'spec_helper'

require 'everbox_client/runner'

module EverboxClient
  describe Runner do
    it "should works" do
      Runner.new.ls
    end
  end
end
