require 'spec_helper'

require 'everbox_client/runner'

module EverboxClient
  describe Runner do
    it "should works" do
      Runner.new.ls
    end

    describe :initialize do
      it "should honor :proxy" do
        OAuth::Consumer.should_receive(:new).with(any_args(), any_args(), {:site=>"http://account.everbox.com", :proxy=>"http://127.0.0.1:80"})
        runner = Runner.new :proxy => 'http://127.0.0.1:80'
        runner.send :consumer
      end
    end
  end
end
