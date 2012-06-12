#!/usr/bin/env ruby

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'
require 'sigar'

class InterfaceGraphite < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    :description => "Metric naming scheme, text to prepend to metric",
    :short => "-s SCHEME",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.interface"

  def run

    sigar = Sigar.new
      iflist = sigar.net_interface_list

      iflist.each do |ifname|
        ifconfig = sigar.net_interface_config(ifname)
        flags = ifconfig.flags
        #encap = ifconfig.type

        if (flags & Sigar::IFF_UP) == 0
          next
        end

        if (!ifname.include?(":"))
          ifstat = sigar.net_interface_stat(ifname)

          rx_bytes = ifstat.rx_bytes
          tx_bytes = ifstat.tx_bytes

          mate = {
              ifname =>{
                  :rx_Packets => ifstat.rx_packets.to_i,
                  :rx_Errors => ifstat.rx_errors.to_i,
                  :rx_Drops => ifstat.rx_dropped.to_i,
                  :rx_Overruns => ifstat.rx_overruns.to_i,
                  :rx_Frame => ifstat.rx_frame.to_i,
                  :rx_Bytes => rx_bytes.to_i,
                  :tx_Packets => ifstat.tx_packets.to_i,
                  :tx_Errors => ifstat.tx_errors.to_i,
                  :tx_Drops => ifstat.tx_dropped.to_i,
                  :tx_Overruns => ifstat.tx_overruns.to_i,
                  :tx_Carrier => ifstat.tx_carrier.to_i,
                  :tx_Collisions => ifstat.tx_collisions.to_i,
                  :tx_Bytes => tx_bytes.to_i
              }
          }

          timestamp = Time.now.to_i

          mate.each do |name, key|
            key.each do |child, value|
              output [config[:scheme],name,child].join("."), value, timestamp
            end
          end

        end
      end
  end

end
