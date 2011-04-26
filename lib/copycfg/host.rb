# Copycfg::Host
# Computer Action Team
# Maseeh College of Engineering and Computer Science
#
# Provides for an individual host to copy

require "fileutils"
require "net/sftp"

class Copycfg::Host

  attr_reader :name
  attr_accessor :files

  def initialize hostname, basedir, sftpopts
    @name       = hostname
    @files      = []
    @sftpopts   = sftpopts
    @destdir    = "#{basedir}/hosts/#{@name}"
    @backupdir  = "#{basedir}/backups/#{@name}"
  end

  def share
    if File.exist? @destdir
      %x{share -F nfs -o sec=sys,ro=#{@name},anon=0 #{@destdir} > /dev/null 2>&1}
    end
  end

  def unshare
    if File.exist? @destdir
      %x{unshare "#{@destdir}" > /dev/null 2>&1}
    end
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
      Copycfg.logger.debug { "#{@name} has no specific configuration files, using filegroup default" }
      @files += config["filegroups"]["default"]
    end
  end

  def expired? days
    completed? and File.stat("#{@destdir}/.completed").ctime < (Time.now - 60*60*24*days)
  end

  def completed?
    File.exist? "#{@destdir}/.completed"
  end

  def removeconfigs
    FileUtils.rm_r @destdir, :secure => true, :force => true
  end

  def backup
    if completed?
      if File.exist? @backupdir
        FileUtils.rm_r @backupdir, :secure => true, :force => true
      else
        FileUtils.mkdir_p File.dirname @backupdir
      end
      FileUtils.mv @destdir, @backupdir
    end
  end

  def restore
    if File.exist? "#{@backupdir}/.completed"
      FileUtils.cp_r "#{@backupdir}/.", @destdir, { :preserve => true }
    end
  end


  # Attempts to connect to a host and then run a copy on every file.
  def copy

    backup

    begin
      Net::SFTP.start(
        @name,
        @sftpopts["user"],
        :auth_methods => ["publickey"],
        :keys => [@sftpopts["key"]],
        :timeout => 1
       ) do |sftp|

        Copycfg.logger.debug { "Connected to #{@name}" }
        @files.each do | file |
          copyfile sftp, file
        end
      end

    rescue Timeout::Error => e
      Copycfg.logger.warn { "Timed out while to #{@name}: #{e}" }
    rescue Net::SSH::AuthenticationFailed => e
      Copycfg.logger.warn { "Failed to connect to #{@name}: access denied for #{e}" }
    rescue RuntimeError => e
      Copycfg.logger.warn { "Failed to copy #{@name}: #{e}" }
    end

    if not completed?
      removeconfigs
      restore
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

    FileUtils.touch "#{@destdir}/.completed"
    Copycfg.logger.debug { "Copied #{@name}:#{file} to #{@destdir}/#{file}" }
  end
end
