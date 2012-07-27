#!/usr/bin/env ruby
#
# This handler just spits out its config and the event it read.
#
# code dn365
#


require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'
require "/etc/sensu/redis-event"

class SystemEvent < Sensu::Handler
  
  def handle
    client_name = @event['client']['name']
    check_name = @event['check']['name']
    #check_output = @event['check']['output']
    status = @event['check']['status']
    event = Sethandler.new("#{client_name}","#{check_name}")
    time = Time.now.to_i
    difftime = (time - event.put_event.to_i)/60
    
    if @event['action'].eql?("resolve")
      return
    else
      case status
      when 1
        puts "#{client_name} #{check_name} warnning ..."
      when 2
        unless event.put_event == nil
          if difftime > 60
            event.set_event("#{time}")
            puts "update #{client_name} #{check_name} crile ..."
            `knife tag create #{client_name} #{check_name}`
            `mco rpc runchef run -F hostname=#{client_name}`
          end
          exit
        end
          
        event.set_event("#{time}")
        puts "create #{client_name} #{check_name} crile"
        `knife tag create #{client_name} #{check_name}`
        `mco rpc runchef run -F hostname=#{client_name}`       
      end       
    end
  end

end