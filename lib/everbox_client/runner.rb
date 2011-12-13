# encoding: utf-8
require 'fileutils'
require 'yaml'
require 'digest/sha1'
require 'pp'

require 'oauth'
require 'json'
require 'highline/import'
require 'restclient'
require 'launchy'

require 'everbox_client'
require 'everbox_client/exceptions'


class ResponseError < RuntimeError
  attr_accessor :response
  def initialize(response)
    @response = response
  end

  def to_s
    "code=#{response.code}|body=#{response.body}"
  end
end

class File
  # expan_path in unix style
  def self.expand_path_unix(*args)
    res = self.expand_path(*args)
    if res[0] != '/'
      res = res[res.index("/"), res.size]
    end
    res
  end
end

module EverboxClient
  class Runner
    DEFAULT_OPTIONS = {
      :pwd => '/home',
      :config_file => '~/.everbox_client/config',
      :consumer_key => 'TFshQutcGMifMPCtcUFWsMtTIqBg8bAqB55XJO8P',
      :consumer_secret => '9tego848novn68kboENkhW3gTy9rE2woHWpRwAwQ',
      :oauth_site => 'http://account.everbox.com',
      :fs_site => 'http://fs.everbox.com',
      :chunk_size => 1024*1024*4

    }

    def initialize(opts={})
      opts ||= {}
      config_file = opts[:config_file] || DEFAULT_OPTIONS[:config_file]
      @options = DEFAULT_OPTIONS.merge(load_config(config_file)).merge(opts)
    end

    def help(arg = nil)
      case arg
      when nil
        puts "Usage: everbox help COMMAND"
      when 'cat'
        puts "Usage: everbox cat [PATH]..."
      when 'cd'
        puts <<DOC
Usage: everbox cd [newpath]
切换工作目录, newpath 可以是相对路径或者绝对路径, 没有 newpath 会切换目录到 "/home"
注意: cd 并不会检查服务器上该目录是否真的存在
DOC
      when 'config'
        puts <<DOC
Usage:
  everbox config
  显示当前的配置

  everbox config KEY VALUE
  设置配置
DOC
      when 'get'
        puts <<DOC
Usage: everbox get [-u] FILENAME
下载文件, 注意可能会覆盖本地的同名文件, 如果指定 "-u", 则只打印下载 url
DOC
      when 'info'
        puts <<DOC
Usage: everbox info
显示用户信息
DOC
      when 'login'
        puts <<DOC
Usage:

  everbox login [username [password]]
  登录 everbox, 登录完成后的 token 保存在 $HOME/.everbox_client/config

  everbox login --oauth
  以 OAuth 方式登录
DOC
      when 'ls'
        puts <<DOC
Usage: everbox ls [path]
显示当前目录下的文件和目录
DOC
      when 'lsdir'
        puts <<DOC
Usage: everbox lsdir
显示当前目录下的目录
DOC

      when 'mirror'
        puts <<DOC
Usage:
  everbox mirror DIRNAME
  下载目录到本地

  everbox mirror -R DIRNAME
  上传目录到服务器
DOC
      when 'mkdir'
        puts <<DOC
Usage: everbox mkdir DIRNAME
创建目录
DOC
      when 'prepare_put'
        puts <<DOC
Usage: everbox prepare_put FILENAME
只运行 prepare_put 部分
DOC
      when 'put'
        puts <<DOC
Usage: everbox put FILENAME [FILENAME]...
上传文件
DOC
      when 'pwd'
        puts <<DOC
Usage: everbox pwd
显示当前目录
DOC
      when 'rm'
        puts <<DOC
Usage: everbox rm DIRNAME [DIRNAME]...
删除文件或目录
DOC
      else
        puts "Not Documented"
      end
    end

    def config(*args)
      if args.size == 0
        @options.each do |k, v|
          puts "#{k}\t#{v}"
        end
      elsif args.size == 2
        @options[args[0].to_sym] = args[1]
      else
        raise "Usage: everbox config [KEY VALUE]"
      end
    end


    def login(*args)
      if args[0] == '-o' or args[0] == '--oauth'
        return login_oauth
      end

      @username = args.shift
      @password = args.shift

      raise "too many arguments" unless args.empty?

      if @username.nil?
        @username = ask("Enter your username:  ") { |q| q.echo = true }
      end
      if @password.nil?
        @password = ask("Enter your password:  ") { |q| q.echo = "*" }
      end

      response = consumer.request(:post, "/oauth/quick_token?login=#{CGI.escape @username}&password=#{CGI.escape @password}")
      if response.code.to_i != 200
        raise "login failed: #{response.body}"
      end

      d = CGI.parse(response.body).inject({}) do |h,(k,v)|
        h[k.strip.to_sym] = v.first
        h[k.strip]        = v.first
        h
      end

      access_token = OAuth::AccessToken.from_hash(self, d)
      @options[:access_token] = access_token.token
      @options[:access_secret] = access_token.secret
      puts @options.inspect
    end

    def ls(path = '.')
      data = {:path => File.expand_path_unix(path, @options[:pwd])}
      response = access_token.post(fs(:get), JSON.dump(data), {'Content-Type' => 'text/plain' })
      fail response.inspect if response.code != "200"
      info = JSON.parse(response.body)
      info["entries"].each do |entry|
        entry = PathEntry.new(entry)
        puts entry.to_line
      end
    end

    def lsdir
      data = {:path => @options[:pwd]}
      info = JSON.parse(access_token.post(fs(:get), JSON.dump(data), {'Content-Type' => 'text/plain' }).body)
      info["entries"].each do |entry|
        entry = PathEntry.new(entry)
        puts entry.to_line if entry.dir?
      end
    end

    def mkdir(path)
      path = File.expand_path_unix(path, @options[:pwd])
      make_remote_path(path)
    end

    def make_remote_path(path, opts = {})
      data = {
        :path => path,
        :editTime => edit_time
      }
      response = access_token.post(fs(:mkdir), data.to_json, {'Content-Type' => 'text/plain'})
      case response.code
      when "200"
        #
      when "409"
        unless opts[:ignore_conflict]
          raise Exception, "directory already exist: `#{path}'"
        end
      end
    end

    def rm(*pathes)
      fail "at least one path required" if pathes.empty?
      pathes = pathes.map {|path| File.expand_path_unix(path, @options[:pwd])}

      data = {
        :paths => pathes,
      }
      response = access_token.post(fs(:delete), data.to_json, {'Content-Type' => 'text/plain'})
      case response.code
      when "200"
        #
      when "409"
        raise Exception, "directory already exist: `#{path}'"
      else
        raise UnknownResponseException, response
      end
    end


    def get(*args)
      filename = args.shift
      url_only = false
      if filename == '-u'
        url_only = true
        filename = args.shift
      end

      raise ArgumentError, "filename is required" if filename.nil?

      path = File.expand_path_unix(filename, @options[:pwd])
      download_file(path, File.expand_path_unix('.'), :url_only => url_only)
    end

    def cat(*args)
      args.each do |filename|
        path = File.expand_path_unix(filename, @options[:pwd])
        data = {:path => path}
        response = access_token.post(fs(:get), JSON.dump(data), {'Content-Type' => 'text/plain' })
        fail response.inspect if response.code != "200"
        url = JSON.parse(response.body)["dataurl"]
        Net::HTTP.get_response(URI.parse(url)) do |response|
          fail response.inspect if response.code != "200"
          response.read_body do |seg|
            STDOUT.write(seg)
            STDOUT.flush
          end
        end
      end
    end

    def thumbnail(*args)
      args.each do |filename|
        path = File.expand_path_unix(filename, @options[:pwd])
        if ['.flv', '.mp4', '.3gp'].include? File.extname(path).downcase
          aimType = '0x20000'
        else
          aimType = '0'
        end
        data = {:path => path, :aimType => aimType}
        response = access_token.post(fs('/2/thumbnail'), JSON.dump(data), {'Content-Type' => 'text/plain' })
        fail response.inspect if response.code != "200"
        puts JSON.parse(response.body)["url"]
      end
    end

    def download_file(path, local_path, opts = {})
      data = {:path => path}
      info = JSON.parse(access_token.post(fs(:get), JSON.dump(data), {'Content-Type' => 'text/plain' }).body)
      if opts[:url_only]
        puts info["dataurl"]
      else
        puts "Downloading `#{File.basename(path)}' with curl"
        ofname = File.expand_path_unix(File.basename(path), local_path)
        system('curl', '-o', ofname, info["dataurl"])
      end
    end

    def put(*filenames)
      fail "at lease one FILE required" if filenames.empty?
      filenames.each do |filename|
        puts "uploading #{filename}"
        upload_file(filename, @options[:pwd])
        puts
      end
    end

    def prepare_put(filename)
      _get_upload_urls(filename, @options[:pwd])["required"].each do |x|
        puts "#{x["index"]}\t#{x["url"]}"
      end
    end


    def _get_upload_urls(filename, remote_path)
      basename = File.basename(filename)
      target_path = File.expand_path_unix(basename, remote_path)
      keys = calc_digests(filename)
      params = {
        :path      => target_path,
        :keys      => keys,
        :chunkSize => @options[:chunk_size],
        :fileSize  => File.open(filename).stat.size,
        :base      => ''
      }
      JSON.parse(access_token.post(fs(:prepare_put), JSON.dump(params), {'Content-Type' => 'text/plain' }).body)
    end

    def upload_file(filename, remote_path)
      basename = File.basename(filename)
      target_path = "#{remote_path}/#{basename}"
      keys = calc_digests(filename)
      params = {
        :path      => target_path,
        :keys      => keys,
        :chunkSize => @options[:chunk_size],
        :fileSize  => File.open(filename).stat.size,
        :base      => ''
      }
      begin
        response = access_token.post(fs(:prepare_put), JSON.dump(params), {'Content-Type' => 'text/plain' })
        raise ResponseError.new(response) if response.code != '200'
      rescue ResponseError => e
        if e.response.code != '409'
          puts "[PREPARE_PUT] meet #{e.message}, retry"
          retry
        else
          raise
        end
      end
      info = JSON.parse(response.body)
      raise "bad response: #{info}" if info["required"].nil?
      File.open(filename) do |f|
        info["required"].each do |x|
          begin
            puts "upload block ##{x["index"]}"
            f.seek(x["index"] * @options[:chunk_size])
            code, response = http_request x['url'], f.read(@options[:chunk_size]), :method => :put
            if code != 200
              raise code.to_s
            end
          rescue => e
            puts "[UPLOAD_BLOCK] meet #{e.class}: #{e.message}, retry"
            retry
          end
        end
      end


      ftime = (Time.now.to_i * 1000 * 1000 * 10).to_s
      params = params.merge :editTime => ftime, :mimeType => 'application/octet-stream'
      code, response = access_token.post(fs(:commit_put), params.to_json, {'Content-Type' => 'text/plain'})
      pp code, response
    rescue ResponseError
      raise
    rescue => e
      puts "[UPLOAD_FILE] meet #{e.class}: #{e.message}, retry"
      retry
    end


    def dump_config
      config = {}
      [:access_token, :access_secret, :pwd, :consumer_key, :consumer_secret, :oauth_site, :fs_site].each do |k|
        config[k] = @options[k] unless @options[k].nil?
      end
      save_config(@options[:config_file], config)
    end

    def pwd
      puts @options[:pwd]
    end

    def cd(newpath = nil)
      newpath ||= "/home"
      @options[:pwd] = File.expand_path_unix(newpath, @options[:pwd])
      @options[:pwd] = "/home" unless @options[:pwd].start_with? "/home"
      puts "current dir: #{@options[:pwd]}"
    end

    def mirror(*args)
      raise Exception, "everbox mirror [-R] pathname" if args.empty?

      upload = false
      if args[0] == '-R'
        upload = true
        args.shift
      end

      path = args.shift
      if path == '--'
        path = args.shift
      end

      if path.nil? or ! args.empty?
        raise Exception, "everbox mirror [-R] pathname"
      end

      if upload
        upload_path(path)
      else
        download_path(path)
      end
    end

    def upload_path(path)
      local_path = File.expand_path_unix(path)
      remote_path = @options[:pwd]

      jobs = []
      jobs << [remote_path, local_path]
      until jobs.empty?
        remote_path, local_path = jobs.pop
        if File.directory? local_path
          puts "upload dir: #{local_path}"
          new_remote_path = File.expand_path_unix(File.basename(local_path), remote_path)
          begin
            make_remote_path(new_remote_path, :ignore_conflict=>true)
          rescue => e
            puts "[MAKE_REMOTE_PATH] meet #{e.class}: #{e}, retry"
            retry
          end

          remote_filenames = []
          data = {:path => new_remote_path}
          response = access_token.post(fs(:get), JSON.dump(data), {'Content-Type' => 'text/plain' })
          fail response.inspect if response.code != "200"
          info = JSON.parse(response.body)
          info["entries"].each do |entry|
            entry = PathEntry.new(entry)
            remote_filenames << entry.basename if entry.file?
          end

          Dir.entries(local_path).each do |filename|
            next if ['.', '..'].include? filename
            if remote_filenames.include? filename
              puts "file already exist, ignored: #{filename}"
              next
            end
            x = "#{local_path}/#{filename}"
            if ! File.symlink? x and (File.directory? x or File.file? x)
              jobs << [new_remote_path, x]
            end
          end
        elsif File.file? local_path and ! File.symlink? local_path
          puts "uploading #{local_path}"
          begin
            upload_file(local_path, remote_path)
          rescue ResponseError => e
            if e.response.code == "409"
              puts "file already exist, ignored"
            else
              raise e
            end
          end
        end
      end
    end

    def download_path(path)
      local_path = File.expand_path_unix('.')
      remote_path = File.expand_path_unix(path, @options[:pwd])

      jobs = []
      jobs << [remote_path, local_path]

      until jobs.empty?
        remote_path, local_path = jobs.pop
        entry = path_info(remote_path)
        if entry.nil? or entry.deleted?
          next
        end

        if entry.dir?
          new_local_path = File.expand_path_unix(entry.basename, local_path)
          FileUtils.makedirs(new_local_path)
          entry.entries.each do |x|
            jobs << [x.path, new_local_path]
          end
        else
          download_file(remote_path, local_path)
        end
      end
    end

    # 显示用户信息
    def info
      user_info
      puts
      fs_info
    end

    def user_info
      response = access_token.get '/api/1/user_info'
      if response.code == '200'
        res = JSON.parse(response.body)
        if res["code"] == 0
          user = User.new(res["user"])
          puts user
          return
        end
      end
      puts "fetch user info failed"
      puts "  code: #{response.code}"
      puts "  body: #{response.body}"
    end

    def fs_info
      response = access_token.get fs :info
      data = JSON.parse(response.body)
      puts "Disk Space Info"
      puts "  used: #{data["used"]}"
      puts "  total: #{data["total"]}"
    end
  protected

    def fs(path)
      path = path.to_s
      path = '/' + path unless path.start_with? '/'
      @options[:fs_site] + path
    end

    def login_oauth
      request_token = consumer.get_request_token
      url = request_token.authorize_url
      puts "open url in your browser: #{url}"
      Launchy.open(url)
      STDOUT.write "please input the verification code: "
      STDOUT.flush
      verification_code = STDIN.readline.strip
      access_token = request_token.get_access_token :oauth_verifier => verification_code
      @options[:access_token] = access_token.token
      @options[:access_secret] = access_token.secret
      puts @options.inspect
    end

    def path_info(path)
      data = {:path => path}
      info = JSON.parse(access_token.post(fs(:get), JSON.dump(data), {'Content-Type' => 'text/plain' }).body)
      PathEntry.new(info)
    end

    def consumer
      OAuth::Consumer.new @options[:consumer_key], @options[:consumer_secret], {
        :site => @options[:oauth_site]
      }
    end

    def access_token
      raise "please login first" if @options[:access_token].nil? or @options[:access_secret].nil?
      OAuth::AccessToken.new(consumer, @options[:access_token], @options[:access_secret])
    end

    def load_config(config_file)
      YAML.load_file(File.expand_path_unix(config_file))
    rescue Errno::ENOENT
      {}
    rescue => e
      EverboxClient.logger.info("load config file #{config_file} failed: #{e.class}")
      {}
    end

    def save_config(config_file, config)
      config_file = File.expand_path_unix(config_file)
      FileUtils.makedirs(File.dirname(config_file))
      File.open(config_file, 'w') do |ofile|
        YAML.dump(config, ofile)
      end
    end

    def calc_digests(fname)
      res = []
      File.open(fname) do |ifile|
        while (data = ifile.read(@options[:chunk_size])) do
          res << urlsafe_base64(Digest::SHA1.digest(data))
        end
      end
      res
    end

    def urlsafe_base64(content)
      Base64.encode64(content).strip.gsub('+', '-').gsub('/','_')
    end

    def http_request url, data = nil, options = {}
      begin
        options[:method] = :post unless options[:method]
        case options[:method]
        when :get
          response = RestClient.get url, data, :content_type => options[:content_type]
        when :post
          response = RestClient.post url, data, :content_type => options[:content_type]
        when :put
          response = RestClient.put url, data
        end
        body = response.body
        data = nil
        data = JSON.parse body unless body.empty?
        [response.code.to_i, data]
      rescue => e
        EverboxClient.logger.error e
        code = 0
        data = nil
        body = nil
        res = e.response if e.respond_to? :response
        begin
          code = res.code if res.respond_to? :code
          body = res.body if res.respond_to? :body
          data = JSON.parse body unless body.empty?
        rescue
          data = body
        end
        [code, data]
      end
    end

    def edit_time(time = nil)
      time ||= Time.now
      (time.to_i * 1000 * 1000 * 10).to_s
    end

  end
end
