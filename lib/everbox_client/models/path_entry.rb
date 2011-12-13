module EverboxClient
  class PathEntry
    MASK_FILE = 0x1
    MASK_DIR = 0x2
    MASK_DELETED = 0x8000

    def initialize(data)
      @data = data
    end

    def basename
      @data["path"].split('/')[-1]
    end

    def file?
      (@data["type"] & MASK_FILE) != 0
    end

    def dir?
      (@data["type"] & MASK_DIR) != 0
    end

    def deleted?
      (@data["type"] & MASK_DELETED) != 0
    end

    def entries
      @entries ||= 
        begin
          if @data["entries"].nil?
            []
          else
            @data["entries"].map {|x| PathEntry.new(x)}
          end
        end
    end

    def path
      @data["path"]
    end

    def to_line
      suffix = dir? ? '/' : ''
      "#{"%10d" % @data["fileSize"]}\t#{basename}#{suffix}\n"
    end
  end
end
