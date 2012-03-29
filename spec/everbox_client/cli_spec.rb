require 'spec_helper'

require 'everbox_client/cli'

module EverboxClient
  describe CLI do
    context "#parse_env" do
      before do
        @cli = CLI.new
      end

      it "when ENV['http_proxy'] set" do
        ENV['http_proxy'] = 'http://1.2.3.4:3128'
        @cli.send :parse_env
        RestClient.proxy.should == ENV['http_proxy']
        RestClient.proxy = nil
        ENV['http_proxy'] = nil
      end


      it "when ENV['http_proxy'] not set" do
        ENV['http_proxy'] = nil
        @cli.send :parse_env
        RestClient.proxy.should be_nil
      end
    end
  end
end
