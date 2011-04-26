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

      if options[:configfile]
        Copycfg.loadconfig options[:configfile]
      else
        # TODO figure out a sensible place for a default config. Homedir?
        Copycfg.loadconfig File.expand_path(File.dirname(__FILE__) + "/copycfg.yaml")
      end

      if options[:netgroups]
        copy_netgroup options[:netgroups]
      end

      if options[:share]
        share
      end
    end

    def copy_netgroup netgroups

      netgroups.each do | netgroupname |

        netgroup = Copycfg::Netgroup.new(netgroupname, Copycfg.config["ldap"]["connection"], Copycfg.config["ldap"]["base"])
        hosts = netgroup.gethosts
        Copycfg.logger.info { "Got #{hosts.size} host(s) from netgroup #{netgroup.name}" }

        hosts.each do | host |
          Copycfg.logger.info { "Copying #{host}" }
          host = Copycfg::Host.new(host, Copycfg.config["basedir"])
          host.files_from_yaml Copycfg.config
          host.copy
        end

      end
    end

    def share
      $stderr.puts "Copycfg::Application.share: not implemented"
      exit 1
    end

    # Provide default arguments, parse args, and validate them
    def parse(args)
      options = {}
      options[:verbosity] = Logger::ERROR
      options[:netgroups]  = []

      opt_parser = OptionParser.new do |opts|
        opts.banner = "#{$0} [options]"

        opts.on('-c', '--config=val', 'Location of YAML configuration file' ) do |configfile|
          options[:configfile] = configfile
        end

        opts.on('-n', '--netgroup=val', 'Netgroup to copycfg-ify' ) do |netgroup|
          options[:netgroups] << netgroup
        end

        opts.on('-s', '--share', 'Share all hosts' ) do
          options[:share] = true
        end

        opts.on('-v', '--verbose', 'Increase verbosity' ) do
          options[:verbosity] -= 1
        end

        opts.on('-h', '--help', 'Display this help') do
          puts opts
          exit
        end

      end

      # Attempt to parse things, explode if this fails.
      begin
        opt_parser.parse! args
      rescue
        $stderr.puts $!
        exit 1
      end

      # Ensure that we have at least one netgroup and we're not just resharing
      if options[:netgroups].length <= 0 and not options[:share]
        $stderr.puts "Error: at least one netgroup must be specified."
        puts opt_parser
        exit 1
      end

      options
    end
  end
end
