# Copycfg::Application
# Computer Action Team
# Maseeh College of Engineering and Computer Science
#
# This provides a singleton class that serves as the entry point for copycfg
# as a standalone application

require "optparse"
require "copycfg"
require "copycfg/netgroup"
require "copycfg/config"
require "copycfg/host"

module Copycfg::Application

  class << self

    # Set configuration options and execute the relevant code
    def run(args)

      options = parse(args)

      Copycfg.logger.level = options[:verbosity]
      Copycfg.loadconfig options[:configfile]

      case options[:action]
      when "share"
        Copycfg.shareall
      when "unshare"
        Copycfg.unshareall
      when "copy"
        options[:netgroups].each { | ng | copy_netgroup ng }
        options[:hosts].each { | h | copy_host h }
      end
    end

    def copy_netgroup name

      netgroup = Copycfg::Netgroup.new(name, Copycfg.config["ldap"]["connection"], Copycfg.config["ldap"]["base"])
      hosts = netgroup.gethosts
      Copycfg.logger.info { "Got #{hosts.size} host(s) from netgroup #{netgroup.name}" }

      hosts.each { | host | copy_host host }
    end

    def copy_host host
      Copycfg.logger.info { "Copying #{host}" }
      host = Copycfg::Host.new(host, Copycfg.config["basedir"], Copycfg.config["sftp"])
      host.files_from_yaml Copycfg.config
      host.copy
    end

    # Provide default arguments, parse args, and validate them
    def parse(args)

      options = {}
      options[:verbosity] = Logger::ERROR
      options[:netgroups] = []
      options[:hosts] = []

      opt_parser = OptionParser.new do |opts|
        opts.banner = "#{$0} [options]"

        opts.on('-a', '--action=val', %w{share unshare copy}, 'The action to take',
                "  share: share all configuration directories",
                "  unshare: unshare all configuration directories",
                "  copy: copy configurations off the specified hosts and netgroups"
        ) do |action|
          if options[:action]
            raise ArgumentError, "Error: --action can only be used once"
          else
            options[:action] = action
          end
       end

       opts.on('-n', '--netgroup=val', 'Netgroup to copy configurations from' ) do |netgroup|
         options[:netgroups] << netgroup
       end

       opts.on('--host=val', 'Netgroup to copy configurations from' ) do |host|
         options[:hosts] << host
       end

       opts.on('-c', '--config=val', 'Location of YAML configuration file' ) do |configfile|
         options[:configfile] = configfile
       end

       opts.on('-v', '--verbose', 'Increase verbosity' ) do
         options[:verbosity] -= 1
       end

       opts.on_tail('-h', '--help', 'Display this help') do
         puts opts
         exit
       end

      end

      # Attempt to parse things, explode if this fails.
      begin
        opt_parser.parse! args
      rescue
        $stderr.puts $!
        $stderr.puts opt_parser
        exit 1
      end

      # Ensure that we have at least one netgroup and we're not just resharing
      unless options[:action]
        $stderr.puts "Error: no operation specified"
        puts opt_parser
        exit 1
      end

      # Ensure that a config was passed. This will be needed until a default
      # config location is used.
      if not options[:configfile]
        $stderr.puts "Error: -c option must be passed"
        puts opt_parser
        exit 1
      end

      options
    end
  end
end
