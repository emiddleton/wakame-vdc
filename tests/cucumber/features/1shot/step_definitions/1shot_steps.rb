# encoding: utf-8
begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

require 'rubygems'
require 'httparty'

Before do
end

After do
end

Given /^(wmi-[a-z0-9]{1,8}) and (is-[a-z0-9]{1,8}) exist$/ do |image_id,spec_id|
  unless APITest.get("/images/#{image_id}").success?
    #Set variabled for the setup script
    ENV["vdc_root"]=VDC_ROOT
    ENV["vmimage_snap_uuid"]=image_id.split("-").last
    ENV["account_id"]="a-shpoolxx"
    ENV["local_store_path"]="#{VDC_ROOT}/tmp/snap/#{ENV["account_id"]}"
    ENV["vmimage_file"]="snap-#{image_id.split("-").last}.snap"
    ENV["vmimage_s3"]="http://dlc.wakame.axsh.jp.s3.amazonaws.com/demo/vmimage/ubuntu-lucid-kvm-ms-32.raw.gz"
    ENV["dcmgr_dbname"]="wakame_dcmgr"
    ENV["dcmgr_dbuser"]="root"
    ENV["image_arch"]="x86"
    
    steps %Q{
      Given the working directory is tests/cucumber/features/1shot/setup_script
      When the following command is run: ./1shot_setup.sh
      Then the command should be successful
    }
  end
  
  unless APITest.get("/instance_specs/#{spec_id}").success?
    steps %Q{
      Given the working directory is dcmgr/bin
      When the following command is run: ./vdc-manage spec add --uuid #{spec_id} --account-id a-shpoolxx --hypervisor kvm --arch x86_64 --cpu-cores 1 --memory-size 256 --quota-weight 1.0
      Then the command should be successful
    }
  end
end

When /^we make a successful api (create|update|delete) call to (.*) with the following options$/ do |call,suffix,options |
  step "we make an api #{call} call to #{suffix} with the following options", options
    
  step "the #{call} call to the #{suffix} api should be successful"
end

When /^we successfully start an instance of (.*) and (.+) with the new security group and key pair$/ do |image,spec|
  steps %Q{
    When we make a successful api create call to instances with the following options
      | image_id | instance_spec_id | ssh_key_id                                            | security_groups                                         |
      | #{image} | #{spec}          | #{@api_call_results["create"]["ssh_key_pairs"]["id"]} | #{@api_call_results["create"]["security_groups"]["id"]} |
    
    Then the create call to the instances api should be successful
  }
end

When /^we (attach|detach) the created volume$/ do |operation|
  steps %Q{
    When we make a successful api update call to volumes/#{@api_call_results["create"]["volumes"]["id"]}/#{operation} with the following options
    | instance_id                                       | volume_id                                       |
    | #{@api_call_results["create"]["instances"]["id"]} | #{@api_call_results["create"]["volumes"]["id"]} |
  }
end

When /^we successfully (attach|detach) the created volume$/ do |operation|
  steps %Q{
    When we #{operation} the created volume
    
    Then the update call to the volumes/#{@api_call_results["create"]["volumes"]["id"]}/#{operation} api should be successful
  }
end

When /^we create a snapshot from the created volume$/ do
  steps %Q{
    When we make an api create call to volume_snapshots with the following options
    | volume_id                                       | destination |
    | #{@api_call_results["create"]["volumes"]["id"]} | local       |
  }
end

When /^we successfully create a snapshot from the created volume$/ do
  steps %Q{
    When we create a snapshot from the created volume
    
    Then the create call to the volume_snapshots api should be successful
  }
end

When /^we delete the created (.+)$/ do |suffix|
  steps %Q{
    When we make an api delete call to #{suffix}/#{@api_call_results["create"][suffix]["id"]} with no options
    
  }
end

When /^we successfully delete the created (.+)$/ do |suffix|
  steps %Q{
    When we delete the created #{suffix}
    
    Then the delete call to the #{suffix}/#{@api_call_results["create"][suffix]["id"]} api should be successful
  }
end

When /^we create a volume from the created snapshot$/ do
  steps %Q{
    When we make an api create call to volumes with the following options
      | snapshot_id                                                       |
      | #{@api_call_results["create"]["volume_snapshots"]["id"]}          |
  }
end

When /^we successfully create a volume from the created snapshot$/ do
  steps %Q{
    When we create a volume from the created snapshot
    
    Then the create call to the volumes api should be successful
  }
end

When /^we (reboot|stop|start) the created instance$/ do |operation|
  steps %Q{
    When we make an api update call to instances/#{@api_call_results["create"]["instances"]["id"]}/#{operation} with no options
  }
end

When /^we successfully (reboot|stop|start) the created instance$/ do |operation|
  steps %Q{
    When we #{operation} the created instance
    
    Then the update call to the instances/#{@api_call_results["create"]["instances"]["id"]}/#{operation} api should be successful
  }
end

Then /^we should be able to ping the started instance in (\d+) seconds or less$/ do |seconds|
  steps %Q{
    Then we should be able to ping #{@api_call_results["create"]["instances"]["id"]} in #{seconds} seconds or less
  }
end

Then /^the started instance should start ssh in (\d+) seconds or less$/ do |seconds|
  steps %Q{
    Then #{@api_call_results["create"]["instances"]["id"]} should start ssh in #{seconds} seconds or less
  }
end

Then /^we should be able to log into the started instance with user (.+) in (\d+) seconds or less$/ do |user, seconds|
  steps %Q{
    Then we should be able to log into #{@api_call_results["create"]["instances"]["id"]} with user #{user} in #{seconds} seconds or less
  }
end
