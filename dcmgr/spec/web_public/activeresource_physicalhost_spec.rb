require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "physical host access by active resource" do
  include ActiveResourceHelperMethods
  before(:all) do
    reset_db
    @class = ar_class :PhysicalHost
  end
  
  it "should add" do
    physicalhost = @class.create(:cpus=>4,
                                 :cpu_mhz=>1.0,
                                 :memory=>2.0,
                                 :hypervisor_type=>'xen')
    physicalhost.id.length.should > 0
    
    real_physicalhost = PhysicalHost[physicalhost.id]
    real_physicalhost.should be_valid
    real_physicalhost.id.should > 0
    real_physicalhost.uuid.length.should > 0
    real_physicalhost.cpus.should == 4
    real_physicalhost.cpu_mhz.should == 1.0
    real_physicalhost.memory.should == 2.0
    real_physicalhost.hypervisor_type.should == 'xen'
    real_physicalhost.tags.include?(Tag.system_tag(:STANDBY_INSTANCE)).should be_true
    $physicalhost_id = physicalhost.id
  end

  it "should remove tag" do
    physicalhost = @class.create(:cpus=>4,
                                 :cpu_mhz=>1.0,
                                 :memory=>2.0,
                                 :hypervisor_type=>'xen')
    physicalhost.put(:remove_tag, :tag=>Tag.system_tag(:STANDBY_INSTANCE).uuid)
    real_physicalhost = PhysicalHost[physicalhost.id]
    real_physicalhost.tags.include?(Tag.system_tag(:STANDBY_INSTANCE)).should be_false
  end

  it "should get list" do
    list = @class.find(:all)
    list.index { |ph| ph.id == $physicalhost_id }.should be_true
  end
  
  it "should delete" do
    id = $physicalhost_id
    lambda {
      @class.find(id).destroy
    }.should change{ PhysicalHost[id] }
  end
end
