#!/usr/bin/env ruby
#
# This handler just spits out its config and the event it read.
#
# code dn365
#


require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-handler'

class ChefTag < Sensu::Handler
  
  def handle
    client_name = @event['client']['name']
    check_name = @event['check']['name']
    check_output = @event['check']['output']
    status = @event['check']['status']
    occ = @event['occurrences']
    noti = @event['check']['notification']
    time = Time.now.strftime("%Y%m%d%H%M%S")
    
    if @event['action'].eql?("resolve")
        puts "1111333333444444555555 #{status} ---$$#{occ}$$--TT#{noti}TT- #{client_name}--#{check_name}---#{check_output}----"
        stat = File.open("/tmp/ok-#{time}.txt","w")
        stat.puts("time:#{Time.now}")
        stat.close
    else
      case status
        when 1
          if check_output.include?("cpu")
              puts "wwwwwwwwwwwwwwwwwwwww--$$$#{occ}$$$--TTT#{noti}TTT--#{client_name}--#{check_name}---#{check_output}-------warning---------wwwwwwwwwwwww"
               stat = File.open("/tmp/waring-#{check_name}-#{time}.txt","w")
                stat.puts("time:#{Time.now}")
                stat.close
          elsif check_output.include?("load")
            puts "wwwwwwwwwwwwwwwwwwwww-------load-----#{check_output}-------warning---------wwwwwwwwwwwww"
          elsif check_output.include?("memory")
            puts "wwwwwwwwwwwwwwwwwwwww-------memory-----#{check_output}-------warning---------wwwwwwwwwwwww"
          else
            puts "wwwwwwwwwwwwwwwwwwwww--other---#{check_output}-------warning---------wwwwwwwwwwwww"
          end               
        when 2
          if check_output.include?("cpu")
            puts "wwwwwwwwwwwwwwwwwwwww-------#{client_name}--#{check_name}-----#{check_output}-------critical---------wwwwwwwwwwwww"
          elsif check_output.include?("load")
            puts "wwwwwwwwwwwwwwwwwwwww-------load-----#{check_output}-------critical---------wwwwwwwwwwwww"
          elsif check_output.include?("memory")
            puts "wwwwwwwwwwwwwwwwwwwww-------memory-----#{check_output}-------critical---------wwwwwwwwwwwww"
          else
            puts "wwwwwwwwwwwwwwwwwwwww-----#{check_output}-------critical---------wwwwwwwwwwwww"
          end
        end       
    end
  end

end