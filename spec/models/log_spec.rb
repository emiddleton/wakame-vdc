# -*- coding: utf-8 -*-

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "log" do
  include ActiveResourceHelperMethods

  before(:each) do
    Log.destroy
  end
  
  it "should log user login" do
    instance_class = ar_class :Instance
    instance_class.find(Instance[1].uuid)

    log = Log.find(:user_id=>User[1].id, :target_uuid=>User[1].uuid)
    log.should be_true
    log.target_uuid.should == User[1].uuid
    log.action.should == "login"
    log.user.should == User[1]
    log.created_at.should be_close(Time.now, 2)
  end

  it "should log run instance" do
    instance_class = ar_class :Instance
    instance_class.find(Instance[1].uuid)
    instance = instance_class.create(:account=>Account[1].uuid,
                                     :need_cpus=>1, :need_cpu_mhz=>0.5,
                                     :need_memory=>1.0,
                                     :image_storage=>ImageStorage[1].uuid)

    log = Log.find(:user_id=>User[1].id, :target_uuid=>instance.id)
    log.should be_true
    log.target_uuid.should == instance.id
    log.action.should == "run"
    log.user.should == User[1]
    log.created_at.should be_close(Time.now, 2)
  end
  
  it "should log shutdown instance" do
    instance_class = ar_class :Instance
    instance_class.find(Instance[1].uuid)
    instance = instance_class.create(:account=>Account[1].uuid,
                                     :need_cpus=>1, :need_cpu_mhz=>0.5,
                                     :need_memory=>1.0,
                                     :image_storage=>ImageStorage[1].uuid)
    instance.put(:shutdown)

    log = Log.find(:user_id=>User[1].id, :target_uuid=>instance.id, :action=>"shutdown")
    log.should be_true
    log.target_uuid.should == instance.id
    log.action.should == "shutdown"
    log.user.should == User[1]
    log.fsuser.should == "gui"
    log.created_at.should be_close(Time.now, 2)
  end
end
