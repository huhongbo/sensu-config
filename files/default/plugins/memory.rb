#!/usr/bin/env ruby

# memory plugin

# code dn365

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'
require "sigar"

class MemoryGraphite < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    :description => "Metric naming scheme, text to prepend to metric",
    :short => "-s SCHEME",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.memory"

  def run
    # Metrics borrowed from hoardd: https://github.com/coredump/hoardd
    sigar = Sigar.new
    mem = sigar.mem
    swap = sigar.swap

    mate = {
      :memory => {
          :total => mem.total,
          :used => mem.used,
          :free => mem.free
      },
      :sawp => {
        :total => swap.total,
        :used => swap.used,
        :free => swap.free
      },
      :ram => {
          :ram => (mem.ram * 1024)*1024
      }
    }
    timestamp = Time.now.to_i
    #puts mate
    mate.each do |name,key|
      key.each do |child,value|
        output [config[:scheme],name,child].join("."), value, timestamp
      end
    end
    ok


  end

end
