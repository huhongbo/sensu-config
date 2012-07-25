#!/usr/bin/env ruby
# delete sensu client log

require 'rubygems'
client_path = "/var/log"
log_file = "sensu-client.log"

if File.exist?("/etc/init.d/sensu_client")
  # linux  aix
  service = "/etc/init.d/sensu_client restart"
elsif File.exist?("/sbin/init.d/sensu_client")
  # hpux
  service = "/sbin/init.d/sensu_client restart"
else
  puts "Not found service file"
end

log_size = File.size("#{client_path}/#{log_file}")/1024/1024

if log_size.to_i >= 300
  `#{service}`
else
  puts "sensu-clinet log file  #{log_size} M"
end


