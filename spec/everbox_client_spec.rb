require 'everbox_client'

describe EverboxClient do
  it "autoload should works" do
    EverboxClient::PathEntry.should be_a(Class)
  end
end
