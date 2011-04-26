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

  def initialize hostname
    @name       = hostname
    @files      = []
    @destdir    = "#{Copycfg::Config["basedir"]}/hosts/#{@hostname}"
    @backupdir  = "#{Copycfg::Config["basedir"]}/backups/#{@hostname}"
    # TODO Hardcoding this to use Copycfg::Config seems less than preferential

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


  def copy

    Net::SFTP.start(@name, Copycfg::Config["sftp"]["user"],
                    :auth_methods => ["publickey"],
                    :keys => [Copycfg::Config["sftp"]["key"]],
                    :timeout => 1) do |sftp|
      @files.each do | file |
        Copycfg.logger.debug { "Connected to #{@name}" }
        copyfile sftp, file
      end
    end
  end

  private

  # Copies a single file or directory from the remote host to the local host
  def copyfile sftp, file

    # Create base directory for file
    basedir = @destdir + File.dirname(file)
    unless File.directory?(basedir) || mkdir_p(basedir)
      Copycfg.logger.error { "Unable to create directory #{basedir}" }
      return
    end

    # Stat file, copy file, recursively if necessary, and copy perms.
    filestat = @sftp.stat! file
    if filestat.directory?
      sftp.download! file, "#{basedir}/#{file}", :recursive => true
    else
      sftp.download! file, "#{basedir}/#{file}"
    end
    chmod filestats.permissions, "#{@savedir}/#{file}"

    Copycfg.logger.debug { "Copied #{@savedir}/#{file}" }
  end
end
