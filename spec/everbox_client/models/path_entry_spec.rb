require 'spec_helper'

require 'json'

require 'everbox_client'

module EverboxClient
  describe PathEntry do
    context "path" do
      before :each do
        @entry_1 = %Q[{"editTime":"12898149764580000","ver":"MDAwMDAwMDAwMDAwMDAwOQ==","type":2,"path":"/home/foo","fileSize":"1932891"}]
        @path_entry = PathEntry.new(JSON.parse(@entry_1))
      end

      subject { @path_entry }
      it { should_not be_file }
      it { should be_dir }
      it { should_not be_deleted }
      describe :basename do
        subject { @path_entry.basename }
        it { should == "foo" }
      end
      describe :to_line do
        subject { @path_entry.to_line }
        it { should == "   1932891\tfoo/\n" }
      end
    end

    context "file" do
      before :each do
        @entry = %Q[{"editTime":"12898149764580000","ver":"MDAwMDAwMDAwMDAwMDAwOQ==","type":1,"path":"/home/foo","fileSize":"1932891"}]
        @path_entry = PathEntry.new(JSON.parse(@entry))
      end
      subject { @path_entry }
      it { should be_file }
      it { should_not be_dir }
      it { should_not be_deleted }
      describe :basename do
        subject { @path_entry.basename }
        it { should == "foo" }
      end
      describe :to_line do
        subject { @path_entry.to_line }
        it { should == "   1932891\tfoo\n" }
      end
    end
  end
end
