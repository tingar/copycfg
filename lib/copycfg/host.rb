class Copycfg::Host

  def initialize(hostname, savedir)
    @hostname = hostname
    @savedir  = "#{savedir}/#{hostname}"
    @files    = []
  end

  def share
    $stderr.puts "Copycfg::Host share not implemented"
  end

  def backup
    $stderr.puts "Copycfg::Host backup not implemented"
  end

  def copy
    $stderr.puts "Copycfg::Host copy not implemented"
    false
  end
end
