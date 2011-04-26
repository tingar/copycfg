# Copycfg::Host
# Computer Action Team
# Maseeh College of Engineering and Computer Science
#
# Provides for an individual host to copy

require "fileutils"
require "net/sftp"

class Copycfg::Host

  attr_reader :name
  attr_writer :files

  def initialize hostname, basedir
    @name       = hostname
    @files      = []
    @destdir    = "#{@basedir}/hosts/#{@name}"
    @backupdir  = "#{@basedir}/backups/#{@name}"
  end

  # Creates a lists of files from copycfg yaml
  def files_from_yaml config

    # Host specific entry in configuration file.
    if config["hosts"][@host]
      if config["hosts"][@host]["files"]
        @files += config["hosts"][host]["files"]
      end
      if config["hosts"][@host]["filegroups"]
        config["hosts"][@host]["filegroups"].each do | group |
          @files += config["filegroups"][group]
        end
      end
    end

    if @files.empty?
      Copycfg.logger.debug { "#{host} has no specific configuration files, using filegroup default" }
      @files += config["filegroups"]["default"]
    end
  end

  # Creates a lists of files to copy for a host.
  # This moves the burden of processing yaml from the host to the config
  def filelist host, co
    files = []

    # Host specific entry in configuration file.
    if @config["hosts"][host]
      if @config["hosts"][host]["files"]
        files += @config["hosts"][host]["files"]
      end
      if @config["hosts"][host]["filegroups"]
        @config["hosts"][host]["filegroups"].each do | group |
          files += @config["filegroups"][group]
        end
      end
    end

    if files.empty?
      Copycfg.logger.debug { "#{host} has no specific configuration files, using filegroup default" }
      files += @config["filegroups"]["default"]
    end

    files
  end
  def share
    raise NotImplementedError
  end

  def backup
    raise NotImplementedError
  end

  def mkdirs

    unless File.directory?(@destdir) || mkdir_p(@destdir)
      Copycfg.logger.fatal { "Unable to create #{@destdir}" }
    end

    unless File.directory?(@backupdir) || mkdir_p(@destdir)
      Copycfg.logger.fatal { "Unable to create #{@backupdir}" }
    end

  end


  # Attempts to connect to a host and then run a copy on every file.
  def copy

    begin
      Net::SFTP.start(@name, Copycfg.config["sftp"]["user"],
                      :auth_methods => ["publickey"],
                      :keys => [Copycfg.config["sftp"]["key"]],
                      :timeout => 1) do |sftp|
        Copycfg.logger.debug { "Connected to #{@name}" }
        @files.each do | file |
          copyfile sftp, file
        end
      end
    rescue Timeout::Error => e
      Copycfg.logger.warn { "Unable to connect to #{@name}: #{e}" }
    rescue Net::SSH::AuthenticationFailed => e
      Copycfg.logger.warn { "Failed to copy #{@name}: access denied for #{e}" }
    rescue RuntimeError => e
      Copycfg.logger.warn { "Failed to copy #{@name}: #{e}" }
      return
    end

  end

  private

  # Copies a single file or directory from the remote host to the local host
  def copyfile sftp, file

    # Create base directory for file
    basedir = @destdir + File.dirname(file)
    unless File.directory?(basedir) || FileUtils.mkdir_p(basedir)
      Copycfg.logger.error { "Unable to create directory #{basedir}" }
      return
    end

    # Stat file, copy file, recursively if necessary, and copy perms.
    # If anything goes wrong copying a single file, log it and return.
    begin
      filestat = sftp.stat! file
      if filestat.directory?
        sftp.download! file, "#{@destdir}/#{file}", :recursive => true
      else
        sftp.download! file, "#{@destdir}/#{file}"
      end
      FileUtils.chmod filestat.permissions, "#{@destdir}/#{file}"

    rescue Net::SFTP::StatusException => e
      Copycfg.logger.debug { "No such file: #{@name}:#{file}" }
      return
    rescue RuntimeError => e
      Copycfg.logger.warn { "Failed to copy #{@name}:#{file}: #{e}" }
      return
    end

    Copycfg.logger.debug { "Copied #{@name}:#{file} to #{@destdir}/#{file}" }
  end

end
