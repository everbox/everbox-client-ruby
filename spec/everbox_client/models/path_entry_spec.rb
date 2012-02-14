require 'spec_helper'

require 'json'

require 'everbox_client'

module EverboxClient
  describe PathEntry do
    context "path" do
      before :each do
        ENTRY_1 = %Q[{"editTime":"12898149764580000","ver":"MDAwMDAwMDAwMDAwMDAwOQ==","type":2,"path":"/home/foo","fileSize":"1932891"}]
      end

      it "should works" do
        entry = PathEntry.new(JSON.parse(ENTRY_1))
        entry.file?.should be_false
        entry.dir?.should == true
        entry.deleted?.should == false
        entry.basename.should == "foo"
        entry.to_line.should == "   1932891\tfoo/\n"
      end
    end

    context "file" do
      before :each do
        ENTRY_1 = %Q[{"editTime":"12898149764580000","ver":"MDAwMDAwMDAwMDAwMDAwOQ==","type":1,"path":"/home/foo","fileSize":"1932891"}]
      end

      it "should works" do
        entry = PathEntry.new(JSON.parse(ENTRY_1))
        entry.file?.should == true
        entry.dir?.should == false
        entry.deleted?.should == false
        entry.basename.should == "foo"
        entry.to_line.should == "   1932891\tfoo\n"
      end
    end
  end
end
