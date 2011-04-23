# Copycfg::Host
# Computer Action Team
# Maseeh College of Engineering and Computer Science
# 
# Provides for an individual host to copy
class Copycfg::Host

  def initialize hostname
    @hostname = hostname
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
