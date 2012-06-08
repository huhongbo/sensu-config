#!/usr/bin/env ruby
#
# System hpux-ruby memory Plugin
# ===
#
# This plugin uses vmstat to collect basic system metrics, produces
# Graphite formated output.
#
# Copyright 2011 Sonian, Inc <chefs@sonian.net>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'

class VMStat < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    :description => "Metric naming scheme, text to prepend to .$parent.$child",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.vmstat"

  def convert_integers(values)
    values.each_with_index do |value, index|
      begin
        converted = Integer(value)
        values[index] = converted
      rescue ArgumentError
      end
    end
    values
  end

  def run
    pspid = `ps -ef | grep sensu-client|grep -v grep|awk '{print $2}'`.lstrip
    pid = File.open("/var/run/sensu-client.pid", "r").read.to_i
    
    if pspid != pid
      File.open("/var/run/sensu-client.pid","w").write(pspid)
    end
      
    result = convert_integers(`pmap #{pid}|tail -2|head -1`.lstrip.split.join("").split("M"))
    #result = `pmap #{pid}|tail -2|head -1`.lstrip.split.join("").split("M")
    timestamp = Time.now.to_i
    metrics = {
      :ruby_memory => {
        :vsz_total => result[0],
        :rsz_total => result[1]
       }
    }
    metrics.each do |parent, children|
      children.each do |child, value|
        output [config[:scheme], parent, child].join("."), value, timestamp
      end
    end
    ok
  end

end
