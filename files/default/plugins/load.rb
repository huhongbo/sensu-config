#!/usr/bin/env ruby
#
# System VMStat Plugin
# ===
# code dn365

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'
require 'sigar'

class VMStat < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    :description => "Metric naming scheme, text to prepend to .$parent.$child",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.load"

  def run

    loadavg = Sigar.new.loadavg
    timestamp = Time.now.to_i

    metrics = {
      :load => {
        :onemonute => loadavg[0],
        :fivemonute => loadavg[1],
        :fifteenmonute => loadavg[2]
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

