# Copycfg::Netgroup
# Computer Action Team
# Maseeh College of Engineering and Computer Science
# 
# Queries LDAP to retrieve hosts in a netgroup.

require "rubygems"
require "net/ldap"

class Copycfg::Netgroup 

  attr_reader :hosts

  def initialize netgroupname
    @name = netgroupname
    @ldap = Net::Ldap.new
    @hosts = []
  end

  # All ldap configuration options are serialized in ruby. When they're
  # unserialized, you can drop them straight into the open call.
  def bind
    @ldap.open Copycfg.config[:ldap][:connection]
  end

  def query

    filter = Net::LDAP::Filter.eq("cn", @name)

    attrs = %w[ nisNetgroupTriple memberNisNetgroup ]

    @ldap.search( :base => Copycfg.config[:ldap][:base], 
                  :filter => filter, 
                  :attributes => attrs) do | entry |

      entry["nisNetgroupTriple"].each do | triple |
        puts triple
      end

      entry["memberNisNetgroup"].each do | member |
        puts member
      end


    end

  end
end
