# Copycfg::Netgroup
# Computer Action Team
# Maseeh College of Engineering and Computer Science
# 
# Queries LDAP to retrieve hosts in a netgroup.

require "rubygems"
require "net/ldap"

class Copycfg::Netgroup 

  attr_reader :hosts

  def initialize netgroupname, auth
    @name = netgroupname
    @ldap = Net::LDAP.new(auth)
    @hosts = []
  end


  def gethosts

    filter = Net::LDAP::Filter.eq("cn", @name)

    attrs = %w[ nisNetgroupTriple memberNisNetgroup ]

    @ldap.search( :base => Copycfg.config["ldap"]["base"],
                  :filter => filter, 
                  :attributes => attrs) do | entry |

      entry["nisNetgroupTriple"].each do | triple |
        if triple =~ /\(([^,]+),-,\)/
          @hosts << $1
        else
          Copycfg.logger.info { "Got mangled nisNetgroupTriple: #{triple}"}
        end
      end

      entry["memberNisNetgroup"].each do | member |
        # It's objects all the way down!
        # AKA create and query all member netgroups, and add their hosts.
        @hosts << Copycfg::Netgroup.new(member).gethosts
      end

    end

    @hosts
  end
end
