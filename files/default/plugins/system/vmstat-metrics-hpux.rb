#!/usr/bin/env ruby
#
# System VMStat Plugin
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
    result = convert_integers(`vmstat 1 2|tail -n1`.split(" "))
    timestamp = Time.now.to_i
    metrics = {
      :procs => {
         :waiting => result[0],
         :uninterruptible => result[1],
         :sleeper => result[2],
       },
       :memory => {
         :swap_used => result[3],
         :free => result[4]
       },
       :page => {
         :reclaims => result[5],
         :translation_faults => result[6],
         :paged_in => result[7],
         :paged_out => result[8],
         :paged_free => result[9],
         :paged_misses => result[10],
         :paged_scan => result[11]
       },
       :faults => {
         :device_interrupts => result[12],
         :system_calls => result[13],
         :cpu_context_switch => result[14]
       },
       :cpu => {
         :user => result[15],
         :system => result[16],
         :idle => result[17]
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
