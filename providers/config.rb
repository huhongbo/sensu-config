action :create do
  sensu_config = data_bag('sensu-config')
  sensu_config.each do |sensu|
    content_json = data_bag_item("sensu-config","#{sensu}").reject do |key,value|
      %w[id chef_type data_bag].include?(key)
    end
    if sensu == "config"
      file "#{sensu_dir}/config.json" do
        content content_json.to_json
        notifies :restart, resources(:service => "sensu_client")
      end
    end

    if sensu != "config"
      file "#{sensu_dir}/conf.d/#{sensu}.json" do
        content content_json.to_json
      end 
    end
  end  
  
end

action :updated do
  @new_resource.updated_by_last_action(true)
end
