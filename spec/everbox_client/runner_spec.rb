require 'spec_helper'

require 'everbox_client/runner'

module EverboxClient
  describe Runner do
    it "should works" do
      Runner.new.ls
    end

    describe :initialize do
      it "should honor :proxy" do
        OAuth::Consumer.should_receive(:new).with(anything(), anything(), {:site=>"http://account.everbox.com", :proxy=>"http://127.0.0.1:80"})
        runner = Runner.new :proxy => 'http://127.0.0.1:80'
        runner.send :consumer
      end

      it "should honor :proxy from ENV" do
        OAuth::Consumer.should_receive(:new).with(anything(), anything(), {:site=>"http://account.everbox.com", :proxy=>"http://127.0.0.1:81"})
        @old_env = ENV['http_proxy']
        ENV['http_proxy'] = 'http://127.0.0.1:81'
        Runner.new.send :consumer
        ENV['http_proxy'] = @old_env
      end
    end
  end
end
