# Copycfg::Host
# Computer Action Team
# Maseeh College of Engineering and Computer Science
# 
# Provides for an individual host to copy
class Copycfg::Host

  attr_writer :files

  def initialize hostname
    @hostname = hostname
    @files    = []
  end

  def share
    raise NotImplementedError
  end

  def backup
    raise NotImplementedError
  end

  def copy
    raise NotImplementedError
  end
end
