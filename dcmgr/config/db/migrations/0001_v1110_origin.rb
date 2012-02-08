Sequel.migration do
  up do
    create_table :accounts do
      primary_key :id, :type => Integer
      String :uuid, :null => false
      String :description
      TrueClass :enabled, :default => true, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false

      index [:uuid], :unique => true
    end

    create_table :frontend_systems do
      primary_key :id, :type => Integer
      String :kind, :null => false
      String :key, :null => false
      String :credential

      index [:key], :unique => true
    end
    
    create_table :histories do
      primary_key :id, Integer
      String :uuid, :null => false
      String :attr, :null => false
      String :vchar_value
      column :blob_value, File
      DateTime :created_at, :null => false

      index [:uuid, :attr]
      index [:uuid, :created_at]
    end
    
    create_table :host_nodes do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      String :node_id
      String :arch, :null => false
      String :hypervisor, :null => false
      String :name, :null => true
      Integer :offering_cpu_cores, :null => false
      Integer :offering_memory_size, :null => false
      
      index [:account_id]
      index [:node_id]
      index [:uuid], :unique => true
    end
    
    create_table :hostname_leases do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :hostname, :size => 32, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false

      index [:account_id, :hostname], :unique => true
    end
    
    create_table :images do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      Integer :boot_dev_type, :default => 1, :null => false
      String :source, :text => true, :null => false
      String :arch, :null => false
      String :description, :text => true
      String :md5sum, :null => false
      FalseClass :is_public, :default => false, :null => false
      String :state, :default => "init", :null => false
      String :features, :text => true
      
      index [:account_id]
      index [:is_public]
      index [:uuid], :unique => true
    end
    
    create_table :instance_security_groups do
      primary_key :id, :type => Integer
      Integer :instance_id, :null => false
      Integer :security_group_id, :null => false

      index [:instance_id]
      index [:security_group_id]
    end
    
    create_table :instance_nics do
      primary_key :id, :type => Integer
      String :uuid, :null => false
      Integer :instance_id, :null => false
      Integer :network_id
      Integer :nat_network_id
      String :mac_addr, :size => 12, :null => false
      Integer :device_index, :null => false
      DateTime :deleted_at
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:deleted_at]
      index [:instance_id]
      index [:mac_addr]
      index [:uuid], :unique => true
    end
    
    create_table :instance_specs do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      String :hypervisor, :null => false
      String :arch, :null => false
      Integer :cpu_cores, :null => false
      Integer :memory_size, :null => false
      Float :quota_weight, :default => 1.0, :null => false
      String :vifs, :text => true, :default => ''
      String :drives, :text => true, :default => ''
      String :config, :text => true, :null => false, :default => ''
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:account_id]
      index [:uuid], :unique => true
    end
    
    create_table(:instances) do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      Integer :host_node_id
      Integer :image_id, :null => false
      Integer :instance_spec_id, :null => false
      String :state, :default => "init", :null => false
      String :status, :default => "init", :null => false
      String :hostname, :size => 32, :null => false
      String :ssh_key_pair_id
      TrueClass :ha_enabled, :default => true, :null => false
      Float :quota_weight, :default => 0.0, :null => false
      Integer :cpu_cores, :null => false
      Integer :memory_size, :null => false
      String :user_data, :text => true, :null => false
      String :runtime_config, :text => true
      String :ssh_key_data, :text => true
      String :request_params, :text => true, :null => false
      DateTime :terminated_at
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:account_id]
      index [:host_node_id]
      index [:state]
      index [:terminated_at]
      index [:uuid], :unique => true
    end
    
    create_table :ip_leases do
      primary_key :id, :type => Integer
      Integer :instance_nic_id
      Integer :network_id, :null => false
      String :ipv4, :size => 50
      Integer :alloc_type, :default => 0, :null => false
      String :description, :text => true
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:instance_nic_id, :network_id]
      index [:network_id, :ipv4], :unique => true
    end
    
    create_table :job_states do
      primary_key :id, :type => Integer
      String :job_id, :size => 80, :null => false
      String :parent_job_id, :size => 80
      String :node_id, :null => false
      String :state, :null => false
      String :message, :text => true
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      DateTime :started_at
      DateTime :finished_at
      
      index [:job_id], :unique => true
    end
    
    create_table :mac_leases do
      primary_key :id, :type => Integer
      String :mac_addr, :fixed => true, :size => 12, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:mac_addr], :unique => true
    end
    
    create_table :security_groups do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      String :description, :text => true
      String :rule, :text => true
      
      index [:account_id]
      index [:uuid], :unique => true
    end
    
    create_table :security_group_rules do
      primary_key :id, :type => Integer
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      Integer :security_group_id, :null => false
      String :permission, :null => false

      index [:security_group_id]
    end
    
    create_table :networks do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      String :ipv4_network, :null => false
      String :ipv4_gw
      Integer :prefix, :default => 24, :null => false
      Integer :metric, :default => 100, :null => false
      String :domain_name
      String :dns_server
      String :dhcp_server
      String :metadata_server
      Integer :metadata_server_port
      Integer :bandwidth
      Integer :vlan_lease_id, :default => 0, :null => false
      Integer :nat_network_id
      Integer :physical_network_id
      String :link_interface, :null => false
      String :description, :text => true
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:account_id]
      index [:nat_network_id]
      index [:uuid], :unique => true
    end

    create_table :network_ports do
      primary_key :id, :type=> Integer
      String :uuid, :null => false
      Integer :network_id, :null => false
      Integer :instance_nic_id
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
    end

    create_table :dhcp_ranges do
      primary_key :id, :type => Integer
      Integer :network_id, :null => false
      String :range_begin, :null => false
      String :range_end, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false

      index [:network_id]
    end

    create_table :physical_networks do
      primary_key :id, :type => Integer
      String :name, :null => false
      String :interface
      String :description, :text => true
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false

      index [:name], :unique => true
    end
    
    create_table :node_states do
      primary_key :id, :type => Integer
      String :node_id, :size => 80, :null => false
      String :boot_token, :size => 10, :null => false
      String :state, :size => 10
      DateTime :created_at, :null => false
      DateTime :updated_at,  :null => false
      DateTime :last_ping_at, :null => false
      
      index [:node_id], :unique => true
    end
    
    create_table :quotas do
      primary_key :id, :type => Integer
      Integer :account_id, :null => false
      Float :instance_total_weight
      Integer :volume_total_size
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:account_id], :unique => true
    end
    
    create_table :request_logs do
      primary_key :id, :type => Integer
      String :request_id, :size => 40, :null => false
      String :frontend_system_id, :size => 40
      String :account_id, :size => 40, :null => false
      String :requester_token
      String :request_method, :size => 10, :null => false
      String :api_path, :null => false
      String :params, :text => true, :null => false
      Integer :response_status, :null => false
      String :response_msg, :text => true
      DateTime :requested_at, :null => false
      Integer :requested_at_usec, :null => false
      DateTime :responded_at, :null => false
      Integer :responded_at_usec, :null => false
      
      index [:request_id], :unique => true, :name => :request_id
    end
    
    create_table :ssh_key_pairs do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :fixed => true, :size => 8, :null => false
      String :finger_print, :size => 100, :null => false
      String :public_key, :text => true, :null => false
      String :private_key, :text => true
      String :description, :text => true
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:account_id]
      index [:uuid], :unique => true
    end
    
    create_table :storage_nodes do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      String :node_id, :null => false
      String :export_path, :null => false
      Integer :offering_disk_space, :null => false
      String :transport_type, :null => false
      String :storage_type, :null => false
      String :ipaddr, :null => false
      String :snapshot_base_path, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:account_id]
      index [:node_id]
      index [:uuid], :unique => true
    end
    
    create_table :tag_mappings do
      primary_key :id, :type => Integer
      Integer :tag_id, :null => false
      String :uuid, :null => false
      
      index [:tag_id]
      index [:uuid]
    end
    
    create_table :tags do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      Integer :type_id, :null => false
      String :name, :null => false
      String :attributes
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:account_id]
      index [:account_id, :type_id, :name], :unique => true
      index [:uuid], :unique => true
    end
    
    create_table :vlan_leases do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      Integer :tag_id, :null => false
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:uuid], :unique => true
      index [:account_id]
      index [:tag_id], :unique => true
    end
    
    create_table :volume_snapshots do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      Integer :storage_node_id, :null => false
      String :origin_volume_id, :null => false
      Integer :size, :null => false
      Integer :status, :default => 0, :null => false
      String :state, :default => "initialized", :null => false
      String :destination_key, :null => false
      DateTime :deleted_at
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:uuid], :unique => true
      index [:account_id]
      index [:deleted_at]
      index [:storage_node_id]
    end
    
    create_table :volumes do
      primary_key :id, :type => Integer
      String :account_id, :null => false
      String :uuid, :null => false
      Integer :storage_node_id
      String :status, :default => "initialized", :null => false
      String :state, :default => "initialized", :null => false
      Integer :size, :null => false
      Integer :instance_id
      Integer :boot_dev, :default => 0, :null => false
      String :snapshot_id
      String :host_device_name
      String :guest_device_name
      String :export_path, :null => false
      String :transport_information, :text => true
      String :request_params, :text => true, :null => false
      DateTime :deleted_at
      DateTime :attached_at
      DateTime :detached_at
      DateTime :created_at, :null => false
      DateTime :updated_at, :null => false
      
      index [:uuid], :unique => true
      index [:account_id]
      index [:deleted_at]
      index [:instance_id]
      index [:snapshot_id]
      index [:storage_node_id]
    end

    self[:accounts].insert(
      :id          => 100,
      :uuid        => '00000000',
      :description => 'datacenter system account',
      :updated_at  => Time.now,
      :created_at  => Time.now
    )
    self[:accounts].insert(
      :id          => 101,
      :uuid        => 'shpoolxx',
      :description => 'system account for shared resources',
      :updated_at  => Time.now,
      :created_at  => Time.now
    )
    self[:quotas].insert(
      :id                    => 1,
      :account_id            => 100,
      :instance_total_weight => Dcmgr.conf.account_instance_total_weight,
      :volume_total_size     => Dcmgr.conf.account_volume_total_size,
      :updated_at            => Time.now,
      :created_at            => Time.now
    )
    self[:quotas].insert(
      :id                    => 2,
      :account_id            => 101,
      :instance_total_weight => Dcmgr.conf.account_instance_total_weight,
      :volume_total_size     => Dcmgr.conf.account_volume_total_size,
      :updated_at            => Time.now,
      :created_at            => Time.now
    )
    self[:tags].insert(
      :id         => 1,
      :uuid       => 'shhost',
      :account_id => 'a-shpoolxx',
      :type_id    => 11,
      :name       => "default_shared_hosts",
      :updated_at => Time.now,
      :created_at => Time.now
    )
    self[:tags].insert(
      :id         => 2,
      :uuid       => 'shnet',
      :account_id => 'a-shpoolxx',
      :type_id    => 10,
      :name       => "default_shared_networks",
      :updated_at => Time.now,
      :created_at => Time.now
    )
    self[:tags].insert(
      :id         => 3,
      :uuid       => 'shstor',
      :account_id => 'a-shpoolxx',
      :type_id    => 12,
      :name       => "default_shared_storage",
      :updated_at => Time.now,
      :created_at => Time.now
    )
  end
  
  down do
    drop_table(:accounts, :frontend_systems, :histories, :host_nodes, :hostname_leases, :images, :instance_security_groups, :instance_nics, :instance_specs, :instances, :ip_leases, :job_states, :mac_leases, :security_groups, :security_group_rules, :networks, :node_states, :quotas, :request_logs, :ssh_key_pairs, :storage_nodes, :tag_mappings, :tags, :vlan_leases, :volume_snapshots, :volumes, :dhcp_ranges, :physical_networks)
  end
end
