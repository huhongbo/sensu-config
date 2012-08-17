#!/usr/bin/env ruby
#
# code dn365
# v 0.02
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require "open-uri"
require "yajl"

class CheckGraph < Sensu::Plugin::Check::CLI

  option :base_url,
    :short => '-u',
    :long => '--url=VALUE',
    :description => 'Graphite base url',
    :default => 'http://graphite.zj.chinamobile.com:8080'
  option :time,
    :short => '-s=VALUE',
    :long => '--seconds',
    :description => 'set from time seconds'
  option :target,
    :short => '-t=VALUE',
    :long => '--target',
    :description => 'target name'
  option :crit,
    :short => '-c',
    :long => '--crit=VALUE',
    :description => 'Critical threshold'
  option :warn,
    :short => '-w',
    :long => '--warn=VALUE',
    :description => 'Warning threshold'
  option :reverse,
    :short => '-r',
    :long => '--reverse',
    :description => 'Alert when the value is UNDER warn/crit instead of OVER'
  option :diff,
    :short => '-d',
    :long => '--deff=VALUE',
    :description => 'Diff the latest values between two graphs url'
  option :holt_winters,
    :short => '-W',
    :long => '--holt-winters',
    :description => 'Perform a Holt-Winters check'
  option :alias,
    :short => '-n=VALUE',
    :long => '--alias-name',
    :description => 'alias the target name'
  option :help,
    :short => "-h",
    :long => "--help",
    :description => "Check usage",
    :on => :tail,
    :boolean => true,
    :show_options => true,
    :exit => 0
    
    
  def read_url(url)
    parser = Yajl::Parser.new
    file = parser.parse(open(url).read)
    return file
  end
  
  def grap_data(file) 
    i, x = 0, 0
    file.each do |f|
      data = f["datapoints"].reject {|k,v| [nil].include?(k) }
      data.each do |key,value|
        i += 1
        x += key
      end
    end
    data_value = sprintf("%.2f", x / i )
    return data_value
  end
  
  def stdev_data(file)
    arry = []
    file.each do |f|
      data = f["datapoints"].reject {|k,v| [nil].include?(k) }  
      data.map {|k,v| arry << k }
    end
    unless arry.max == nil
      return sprintf("%.2f", arry.max) 
    else
      return 0
    end
  end
  
  def last_data(file)
    file.each do |f|
      data = f["datapoints"].reject {|k,v| [nil].include?(k) }
      data.each_with_index do |(k,v),index|
        if index == data.length - 1
          return k
        end
      end
    end
  end

  def holt_grap_data(file)
    i, x = 0, 0
    upper_data, lower_data, t_value = 0, 0, 0
    file.each do |f|
      if f["target"].include?("holtWintersConfidenceUpper") 
        data = f["datapoints"].reject {|k,v| [nil].include?(k) }
        data.each do |key,value|
          i += 1
          x += key
        end
        upper_data = sprintf("%.2f", x / i )
      elsif f["target"].include?("holtWintersConfidenceLower")
        data = f["datapoints"].reject {|k,v| [nil].include?(k) }
        data.each do |key,value|
          i += 1
          x += key
        end
        lower_data = sprintf("%.2f", x / i )
      else
        data = f["datapoints"].reject {|k,v| [nil].include?(k) }
        data.each do |key,value|
          i += 1
          x += key
        end
        t_value = sprintf("%.2f", x / i )
      end
    end
    return upper_data, lower_data, t_value
  end

  def run
    base_url = config[:base_url]
    from_time = config[:time]
    target = config[:target]
    if config[:alias] == nil
      alias_name = target
    else
      alias_name = config[:alias]
    end
    
    if base_url.nil? or from_time.nil? or target.nil?
      unknown msg = "Not find url and time and target, please -h" 
    else
      if config[:holt_winters]
        holt_url = "#{base_url}/render?from=-#{from_time}sen&until=now&target=#{target}&target=holtWintersConfidenceBands(#{alias_name})&format=json"
        holt_file = read_url(holt_url)
        upper_data, lower_data, t_value = holt_grap_data(holt_file)
        if (t_value > upper_data) or (t_value < lower_data)
          if t_value > upper_data
            critical msg = "#{alias_name} holtWintersConfidenceUpper: #{t_value} > #{upper_data}"
          else
            warning msg = "#{alias_name} holtWintersConfidenceLower: #{t_value} < #{lower_data}"
          end
        else
          ok msg = "#{alias_name} DATA: #{t_value}"
        end
      elsif config[:diff] != nil 
         diff1_url = "#{base_url}/render?from=-#{from_time}sen&until=now&target=#{target}&format=json"
         diff2_url = "#{base_url}/render?from=-#{from_time}sen&until=now&target=#{config[:diff]}&format=json"
         diff1_data = grap_data(read_url(diff1_url))
         diff2_data = grap_data(read_url(diff2_url))
         diff_data = (diff1_data.to_i - diff2_data.to_i).abs.to_i
         if config[:reverse] == true
           if config[:crit] != nil || config[:warn] != nil
             if config[:crit] == nil
               if diff_data > config[:warn].to_i
                 warning msg = "#{alias_name}: #{diff_data} > #{config[:warn]}"
               else
                 ok msg = "#{alias_name}: #{diff_data} < #{config[:warn]} "
               end
             elsif config[:warn] == nil
               if diff_data > config[:crit].to_i
                 critical msg = "#{alias_name}: #{diff_data} > #{config[:crit]}"
               else
                 ok msg "#{alias_name}: #{diff_data} < #{config[:crit]}"
               end
             else
               if diff_data > config[:crit].to_i
                 critical msg = "#{alias_name}: #{diff_data} > #{config[:crit]}"
               elsif diff_data > config[:warn].to_i
                 warning msg = "#{alias_name}: #{diff_data} > #{config[:warn]}"
               else
                 ok msg = "#{alias_name}: #{diff_data}"
               end
             end
           else
             unknown msg = "Not find -c crit or -w warn ,please -h"
           end
         else
           unknown msg = "Not find -r reverse, please -h"
         end
      else
        grap_url = "#{base_url}/render?from=-#{from_time}sen&until=now&target=#{target}&format=json"
        file = read_url(grap_url)
        if config[:reverse]
          data_value = stdev_data(file)
          if config[:crit] != nil || config[:warn] != nil
            if config[:crit] == nil
              if data_value.to_i > config[:warn].to_i
                warning msg = "#{alias_name}: #{data_value} > #{config[:warn]}"
              else
                ok msg = "#{alias_name}: #{data_value}"
              end
            elsif config[:warn] == nil
              if data_value.to_i > config[:crit].to_i
                critical msg = "#{alias_name}: #{data_value} > #{config[:crit]}"
              else
                ok msg = "#{alias_name}: #{data_value}"
              end
            else
              if data_value.to_i > config[:crit].to_i
                critical msg = "#{alias_name}: #{data_value} > #{config[:crit]}"
              elsif data_value.to_i > config[:warn].to_i
                warning msg = "#{alias_name}: #{data_value} > #{config[:warn]}"
              else
                ok msg = "#{alias_name}: #{data_value}"
              end
            end
          else
            unknown msg = "Not find -c crit or -w warn, please -h"
          end
        else
          data_value = grap_data(file)
          if config[:crit] != nil || config[:warn] != nil
            if config[:crit] == nil
              if data_value.to_i > config[:warn].to_i
                warning msg = "#{alias_name}: #{data_value} > #{config[:warn]}"
              else
                ok msg = "#{alias_name}: #{data_value}"
              end
            elsif config[:warn] == nil
              if data_value.to_i > config[:crit].to_i
                critical msg = "#{alias_name}: #{data_value} > #{config[:crit]}"
              else
                ok msg = "#{alias_name}: #{data_value}"
              end
            else
              if data_value.to_i > config[:crit].to_i
                critical msg = "#{alias_name}: #{data_value} > #{config[:crit]}"
              elsif data_value.to_i > config[:warn].to_i
                warning msg = "#{alias_name}: #{data_value} > #{config[:warn]}"
              else
                ok msg = "#{alias_name}: #{data_value}"
              end
            end
          else
            unknown msg = "Not find -c crit or -w warn, please -h"
          end
        end
      end
    end
  end
end