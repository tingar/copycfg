# Copycfg::Config
# Computer Action Team
# Maseeh College of Engineering and Computer Science
#
# This provides a singleton class to manage the copycfg configuration data.
# Has things like helpers for specific configuration classes

require "yaml"

module Copycfg::Config

  class << self

    # Configuration from YAML
    attr_reader :config

    def loadconfig yamlfile
      File.open(yamlfile) { | yf | @config = YAML::load yf }
    end

    def filelist host
      files = @config["hosts"][host]["files"]

      @config["hosts"][host]["filegroups"].each do | group |
        files += @config["filegroups"][group]
      end
    end

    def [](name)
      @config[name]
    end
  end
end


