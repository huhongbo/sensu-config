#!/usr/bin/env ruby
#
# code dn365
# v 0.01
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'sigar'

class CheckSystem < Sensu::Plugin::Check::CLI
  option :filesystem,
    :short => '-f',
    :long => '--file',
    :description => 'File system used precent warnning'
  option :memory,
    :short => '-m',
    :long => '--memory',
    :description => 'Memory used precent warnning'
  option :swap,
    :short => '-s',
    :long => '--swap',
    :description => 'Swap used 98% warnning'
  option :help,
    :short => "-h",
    :long => "--help",
    :description => "Check usage",
    :on => :tail,
    :boolean => true,
    :show_options => true,
    :exit => 0
    
    def files_system_used(sys_type,mount,size,used,free)
      case sys_type
      when "linux","aix"
        filesys = %x[df -m]
      when "hpux"
        filesys = %x("bdf")
      end
      
      file,message = [],[]
      filesys.each_line do |f|
        file << f
      end

      file[1..-1].each do |f|
        mount_name,disk_used = f.split(" ")[mount],f.split(" ")[used].to_i
        case sys_type
        when "linux","aix"
          disk_size,disk_free = f.split(" ")[size].to_i,f.split(" ")[free].to_i
        when "hpux"
          disk_size,disk_free = f.split(" ")[size].to_i / 1024,f.split(" ")[free].to_i / 1024
        end

        unless mount_name =~ /\/dev|db2|oradata|dbdata|media|proc/
            unless mount_name =~ /arch/
              if disk_size > 2048
                if disk_free <= 2048 && disk_used > 90 && disk_free > 1024
                  message << "warning:#{mount_name} used:#{disk_used}% free:#{disk_free}MB"
                elsif disk_free <=1024 && disk_used >90
                  message << "critical:#{mount_name} used:#{disk_used}% free:#{disk_free}MB"
                else
                  message << "ok:#{mount_name}"
                end
              else
                if disk_used > 90
                  message << "warning:#{mount_name} used:#{disk_used}%"
                elsif disk_used > 95
                  message << "critical:#{mount_name} used:#{disk_used}%"
                else
                  message << "ok:#{mount_name}"
                end     
              end
            else
              if disk_size > 2048
                if disk_free <= 2048 && disk_used > 80 && disk_free > 1024
                  message << "warning:#{mount_name} used:#{disk_used}% free:#{disk_free}MB"
                elsif disk_free <=1024 && disk_used >80
                  message << "critical:#{mount_name} used:#{disk_used}% free:#{disk_free}MB"
                else
                  message << "ok:#{mount_name}"
                end
              else
                if disk_used > 80
                  message << "warning:#{mount_name} used:#{disk_used}%"
                elsif disk_used > 90
                  message << "critical:#{mount_name} used:#{disk_used}%"
                else
                  message << "ok:#{mount_name}"
                end
              end
            end
        end
      end
        warning_count,ok_count,critical_count = [],[],[]
        message.each do |m|     
          warning_count << m.sub(/warning:(.*)/,'\1') if m.include?("warning")
          ok_count << m.sub(/ok:(.*)/,'\1') if m.include?("ok")
          critical_count << m.sub(/critical:(.*)/,'\1') if m.include?("critical")
        end
        if critical_count[0] != nil
          critical msg = "#{critical_count[0..-1].join("; ")}"
        elsif warning_count[0] != nil
          warning msg = "#{warning_count[0..-1].join("; ")}"
        else
          ok msg = "OK"
        end
    end
    
    def sprintf_int(num)
      sprintf("%.0f", num*100)
    end

    def memory_used(sys_type,free,po)
      sigar = Sigar.new
      vmstat = %x[vmstat | tail -n1]
      mem = sigar.mem

      mem_actual = mem.actual_used.to_f
      case sys_type
      when "aix","linux"
        mem_precent = sprintf_int(mem_actual / mem.total).to_i
      when "hpux"
        mem_precent = sprintf_int(mem.used.to_f / mem.total).to_i
      end
      mem_free = vmstat.split(" ")[free].to_i / 1024
      swap_po = vmstat.split(" ")[po].to_i 
      #return mem_precent,swap_precent,mem_free,swap_so
      #puts "mem:#{mem_actual / (1024*1024) } free:#{mem_free}"
      #
      if mem_precent >= 79 && mem_free <= 400 && swap_po >= 400
        critical msg = "Memory:#{mem_precent}%; free:#{mem_free}MB"
      elsif (mem_precent >= 79 && mem_free <= 400 && swap_po >=100)
        warning msg = "Memory: #{mem_precent}%; free:#{mem_free}MB"
      else
        ok msg = "Memory: #{mem_precent}%; free:#{mem_free}MB"
      end 
    end

    def swap_used
      sigar = Sigar.new
      swap = sigar.swap
      swap_precent = sprintf_int(swap.used / swap.total).to_i

      if swap_precent >= 99
        critical msg = "Swap: #{swap_precent}%"
      elsif swap_precent >= 95
        warning msg = "Swap: #{swap_precent}%"
      else
        ok msg = "Swap: #{swap_precent}%"
      end
    end
    
    def run
      uname = %x("uname")
      
      if config[:filesystem]   
        case uname
        when /Linux/
          files_system_used("linux",5,1,4,3)
        when /AIX/
           files_system_used("aix",6,1,3,2)
        when /HP-UX/
           files_system_used("hpux",5,1,4,3)
        end
      elsif config[:memory]
        case uname
        when /Linux/
          memory_used("linux",4,7)
        when /AIX/
          memory_used("aix",3,6)
        when /HP-UX/
          memory_used("hpux",4,8)
        end
      elsif config[:swap]
        swap_used
      else
        unknown msg = "Not find -c crit or -w warn ,please -h"
      end    
    end 
end