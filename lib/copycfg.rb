# Copycfg
# Computer Action Team
# Maseeh College of Engineering and Computer Science
#
# This provides a singleton class that stores settings that need to be shared
# across the entire application.

require "yaml"
require "logger"

module Copycfg
  class << self

    # Configuration from YAML
    attr_reader :config
    # Allow other classes to use a single logger
    attr_reader :logger

    def init
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::ERROR
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    end

    # Loads configuration
    def loadconfig yamlfile
      File.open(yamlfile) { | yf | @config = YAML::load yf }
    end


    def unshareall
      Dir.foreach @config["basedir"] do | dir |
        %x{unshare "#{dir}" > /dev/null 2>&1}
      end
    end

  end
end
