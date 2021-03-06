include Dcmgr::Models

account_a = Account.create(:name=>'__test_account__', :contract_at=>Time.now)
account_b = Account.create(:name=>'__test_account2__')
account_c = Account.create(:name=>'__test_account3__')

user = User.create(:name=>'__test__', :password=>'passwd')
user.add_account(account_a)
user.add_account(account_b)

other_user = User.create(:name=>'__test2__', :password=>'passwd')

image_storage_host = ImageStorageHost.create
image_storage = ImageStorage.create(:image_storage_host=>image_storage_host)

ip_group_newbr0 = IpGroup.create(:name=>'newbr0')
ip_group_eth1 = IpGroup.create(:name=>'eth1')

100.times{|i|
  Ip.create(:ip=>"192.168.1.#{i}",
            :mac=>"00:00:%d" % i,
            :ip_group=>ip_group_newbr0)
  Ip.create(:ip=>"192.168.11.#{i + 200}",
            :mac=>"00:16:%d" % i,
            :ip_group=>ip_group_eth1)
}

physical_host_a = PhysicalHost.create(:cpus=>4, :cpu_mhz=>1.0,
                                      :memory=>2000,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_a.id].remove_tag(Tag.system_tag(:STANDBY_INSTANCE))
physical_host_b = PhysicalHost.create(:cpus=>2, :cpu_mhz=>1.6,
                                      :memory=>1000,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_b.id].remove_tag(Tag.system_tag(:STANDBY_INSTANCE))
physical_host_c = PhysicalHost.create(:cpus=>1, :cpu_mhz=>2.0,
                                      :memory=>8000,
                                      :hypervisor_type=>'xen')
PhysicalHost[physical_host_c.id].remove_tag(Tag.system_tag(:STANDBY_INSTANCE))

hv_controller = HvController.create(:access_url=>'http://192.168.1.10/')

hv_agent_a = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_a,
                            :ip=>'192.168.1.20')
hv_agent_b = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_b,
                            :ip=>'192.168.1.30')
hv_agent_c = HvAgent.create(:hv_controller=>hv_controller,
                            :physical_host=>physical_host_c,
                            :ip=>'192.168.1.40')

instance_a = Instance.create(:status=>Instance::STATUS_TYPE_OFFLINE,
                             :account=>account_a,
                             :user=>user,
                             :image_storage=>image_storage,
                             :need_cpus=>1,
                             :need_cpu_mhz=>0.5,
                             :need_memory=>500,
                             :hv_agent=>hv_agent_a)

ip_a = Ip.first
ip_a.instance = instance_a
ip_a.save

normal_tag_a = Tag.create(:name=>'sample tag a',
                          :account=>account_a)
normal_tag_b = Tag.create(:name=>'sample tag b',
                          :account=>account_a)
normal_tag_c = Tag.create(:name=>'sample tag c',
                          :account=>account_a)

TagMapping.create(:tag=>normal_tag_a,
                  :target_type=>TagMapping::TYPE_INSTANCE,
                  :target_id=>instance_a.id)

Dcmgr::RoleExecutor.roles.each{|role|
  # create role tag
  role_tag = Tag.create(:name=>role.name,
                        :role=>role.id,
                        :account=>account_a,
                        :owner=>user)

  # create normal tag
  tag = Tag.create(:name=>"normal #{role.name}",
                   :account=>account_a,
                   :owner=>user)

  # belongs to normal tag
  role.allow_types.each{|type|
    TagMapping.create(:tag=>tag,
                      :target_type=>type,
                      :target_id=>0)
  }

  # relation role tag, normal tag
  TagMapping.create(:tag=>tag,
                    :target_type=>TagMapping::TYPE_TAG,
                    :target_id=>role_tag.id)
}

