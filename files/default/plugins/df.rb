#!/usr/bin/env ruby
# filesystem plugin

# code dn365

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'
require 'sigar'

class InterfaceGraphite < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    :description => "Metric naming scheme, text to prepend to metric",
    :short => "-s SCHEME",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.filesystem"

  def run

    sigar = Sigar.new
    sigar.file_system_list.each do |fs|
      file_name = fs.dev_name.split("/")

      usage = sigar.file_system_usage(fs.dir_name)
      disk_total = usage.total
      disk_free = usage.free
      disk_use = usage.total - usage.free
      disk_percent = usage.use_percent * 100

      mate = {
        "#{file_name[-1]}" => {
          :total => disk_total,
          :free =>  disk_free,
          :use => disk_use,
          :percent => disk_percent
        }
      }
      timestamp = Time.now.to_i
      #puts mate
      mate.each do |name, key|
       key.each do |child, value|
          #puts name
          output [config[:scheme],name,child].join("."), value, timestamp
        end
      end
      #ok

    end

  end

end
