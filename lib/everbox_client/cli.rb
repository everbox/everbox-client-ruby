require 'pp'

require 'everbox_client/runner'

module EverboxClient
  class CLI
    SUPPORTED_COMMANDS = {
      "login"     => "login",
      "ls"        => "list files and directories",
      "lsdir"     => "list directories",
      "get"       => "download file",
      "put"       => "upload file",
      "prepare_put" => "prepare put",
      "cd"        => "change dir",
      "pwd"       => "print working dir",
      "mkdir"     => "make directory",
      "rm"        => "delete file or directory",
      "mirror"    => "download dir",
      "info"      => "show user info",
      "config"       => "set config",
      "cat"       => "cat file",
      "help"       => "print help info",
      "thumbnail" => "get thumbnail url"
    }

    attr_reader :command
    attr_reader :options
    attr_reader :stdout, :stdin

    def self.execute(stdout, stdin, stderr, arguments = [])
      self.new.execute(stdout, stdin, stderr, arguments)
    end

    def initialize
      @options = {}

      # don't dump a backtrace on a ^C
      trap(:INT) {
        exit
      }
    end

    def execute(stdout, stdin, stderr, arguments = [])
      @stdout = stdout
      @stdin  = stdin
      @stderr = stderr
      extract_command_and_parse_options(arguments)

      if valid_command?
        begin
          runner = EverboxClient::Runner.new @opts
          runner.send @command, *@args
          runner.dump_config
        rescue => e
          raise e
          STDERR.write "Error: #{e.message}\n"
          exit 1
        end
      else
        usage
      end
    end
  protected


    def extract_command_and_parse_options(arguments)
      parse_options(arguments)
      @command, *@args = ARGV
    end
    def option_parser(arguments = "")
      option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] <command>"

        ## Common Options


        #opts.on("--scope SCOPE", "Specifies the scope (Google-specific).") do |v|
        #  options[:scope] = v
        #end
      end
    end

    def parse_options(arguments)
      option_parser(arguments).order!(arguments)
    end

    def prepare_parameters
      escaped_pairs = options[:params].collect do |pair|
        if pair =~ /:/
          Hash[*pair.split(":", 2)].collect do |k,v|
            [CGI.escape(k.strip), CGI.escape(v.strip)] * "="
          end
        else
          pair
        end
      end

      querystring = escaped_pairs * "&"
      cli_params = CGI.parse(querystring)

      {
        "oauth_consumer_key"     => options[:oauth_consumer_key],
        "oauth_nonce"            => options[:oauth_nonce],
        "oauth_timestamp"        => options[:oauth_timestamp],
        "oauth_token"            => options[:oauth_token],
        "oauth_signature_method" => options[:oauth_signature_method],
        "oauth_version"          => options[:oauth_version]
      }.reject { |k,v| v.nil? || v == "" }.merge(cli_params)
    end

    def usage
      stdout.puts option_parser.help
      stdout.puts
      stdout.puts "Available commands:"
      SUPPORTED_COMMANDS.keys.sort.each do |command|
        desc = SUPPORTED_COMMANDS[command]
        puts "   #{command.ljust(15)}#{desc}"
      end
    end

    def valid_command?
      SUPPORTED_COMMANDS.keys.include?(command)
    end

    def verbose?
      options[:verbose]
    end
  end
end
