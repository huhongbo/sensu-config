#!/usr/bin/env ruby
#
# This handler just spits out its config and the event it read.
#
# code dn365
#


require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require "/etc/sensu/redis-event"

class ClientKeepalive < Sensu::Handler
  
  def handle
    client_name = @event['client']['name']
    check_name = @event['check']['name']
    check_output = @event['check']['output']
    status = @event['check']['status']
        
    if @event['action'].eql?("resolve")
      return
    else
      if check_name == "keepalive"
        case status
        when 1
          puts "#{client_name} keepalive 120, run chef client"
          `mco rpc runchef run -F hostname=#{client_name}`
        when 2
               
        end       
      end
    end
  end

end