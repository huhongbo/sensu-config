#
# Cookbook Name:: sensu-config
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
root_group = value_for_platform(
  ["aix"] => { "default" => "system" },
  ["hpux"] => { "default" => "sys" },
  "default" => "root"
)

directory "/etc/sensu" do
  action :create
end
if node["pratform"] == "aix"
  directory "/var/chef/run" do
    owner "root"
    group "system"
    mode 0755
    action :create
  end
end

%w{ conf.d handlers plugins }.each do |dir|
  directory "/etc/sensu/#{dir}" do
    mode 775
    owner "root"
    group root_group
    action :create
    recursive true
  end
end

sensu_dir = "/etc/sensu"
template "#{sensu_dir}/conf.d/client.json" do
  source "client.json.erb"
  mode 0644
  notifies :restart, resources(:service => "sensu_client"), :delayed
end

sensu_config = data_bag('sensu-config')
sensu_config.each do |sensu|
  content_json = data_bag_item("sensu-config","#{sensu}").reject do |key,value|
    %w[id chef_type data_bag].include?(key)
  end
  unless sensu == "config"
    file "#{sensu_dir}/conf.d/#{sensu}.json" do
      content content_json.to_json
      unless node.hostname == "pc-mon02"
        notifies :restart, resources(:service => "sensu_client"), :delayed
    end
  else
    file "#{sensu_dir}/config.json" do
      content content_json.to_json
        notifies :restart, resources(:service => "sensu_client"), :delayed
    end
  end
end
  
node["plugin_files"].each do |pluginfile|
  cookbook_file "/etc/sensu/plugins/#{pluginfile}" do
    source "plugins/#{pluginfile}"
    mode 775
  end
end

node["handler_files"].each do |handlerfile|
  cookbook_file "/etc/sensu/handlers/#{handlerfile}" do
    source "handlers/#{handlerfile}"
    mode 775
  end
end

#service config
conf_dir = value_for_platform(
["aix", "ubuntu"] => {"default" => "/etc/init.d"},
["hpux"] => { "default" => "/sbin/init.d" },
"default" => "/etc/init.d"
)
template "#{conf_dir}/sensu_client" do
  source "sensu_client.erb"
  mode 0755
end

pattern_conf = value_for_platform(
["hpux", "ubuntu"] => {"default" => "sensu-client"},
"default" => "sensu-client"
)

service "sensu_client" do
  if (platform?("hpux"))
    provider Chef::Provider::Service::Hpux
  elsif (platform?("aix"))
    provider Chef::Provider::Service::Init
  end  
    action :start
end
