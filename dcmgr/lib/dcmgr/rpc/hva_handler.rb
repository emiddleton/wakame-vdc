# -*- coding: utf-8 -*-
require 'isono'
require 'fileutils'
require 'ipaddress'

module Dcmgr
  module Rpc
    class HvaHandler < EndpointBuilder
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include Dcmgr::Helpers::NicHelper

      def select_hypervisor
        @hv = Dcmgr::Drivers::Hypervisor.select_hypervisor(@inst[:instance_spec][:hypervisor])
      end

      def attach_volume_to_host
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        tryagain do
          next true if File.exist?(@os_devpath)

          sh("iscsiadm -m discovery -t sendtargets -p %s", [@vol[:storage_node][:ipaddr]])
          sh("iscsiadm -m node -l -T '%s' --portal '%s'",
             [@vol[:transport_information][:iqn], @vol[:storage_node][:ipaddr]])
          # wait udev queue
          sh("/sbin/udevadm settle")
        end

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attaching,
                      :attached_at => nil,
                      :instance_id => @inst[:id], # needed after cleanup
                      :host_device_name => @os_devpath})
      end

      def detach_volume_from_host
        # iscsi logout
        sh("iscsiadm -m node -T '%s' --logout", [@vol[:transport_information][:iqn]])
        # wait udev queue
        sh("/sbin/udevadm settle")
      end

      def update_volume_state_to_available
        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:available,
                      :host_device_name=>nil,
                      :instance_id=>nil,
                      :detached_at => Time.now.utc,
                    })
        event.publish('hva/volume_detached', :args=>[@inst_id, @vol_id])
      end

      def terminate_instance(state_update=false)
        @hv.terminate_instance(HvaContext.new(self))

        unless @inst[:volume].nil?
          @inst[:volume].each { |volid, v|
            @vol_id = volid
            @vol = v
            # force to continue detaching volumes during termination.
            detach_volume_from_host rescue logger.error($!)
            if state_update
              update_volume_state_to_available rescue logger.error($!)
            end
          }
        end
        
        # cleanup vm data folder
        FileUtils.rm_r(File.expand_path("#{@inst_id}", @node.manifest.config.vm_data_dir))
      end

      def update_instance_state(opts, ev)
        raise "Can't update instance info without setting @inst_id" if @inst_id.nil?
        rpc.request('hva-collector', 'update_instance', @inst_id, opts)
        event.publish(ev, :args=>[@inst_id])
      end

      def update_volume_state(opts, ev)
        raise "Can't update volume info without setting @vol_id" if @vol_id.nil?
        rpc.request('sta-collector', 'update_volume', @vol_id, opts)
        event.publish(ev, :args=>[@vol_id])
      end

      def check_interface
        @inst[:instance_nics].each { |vnic|
          network = rpc.request('hva-collector', 'get_network', vnic[:network_id])
          
          fwd_if = phy_if = network[:physical_network][:interface]
          bridge_if = network[:link_interface]
          
          if network[:vlan_id].to_i > 0 && phy_if
            fwd_if = "#{phy_if}.#{network[:vlan_id]}"
            unless valid_nic?(vlan_if)
              sh("/sbin/vconfig add #{phy_if} #{network[:vlan_id]}")
              sh("/sbin/ip link set %s up", [fwd_if])
              sh("/sbin/ip link set %s promisc on", [fwd_if])
            end
          end

          unless valid_nic?(bridge_if)
            sh("/sbin/brctl addbr %s",    [bridge_if])
            sh("/sbin/brctl setfd %s 0",    [bridge_if])
            # There is null case for the forward interface to create closed bridge network.
            if fwd_if
              sh("/sbin/brctl addif %s %s", [bridge_if, fwd_if])
            end
          end
        }
        sleep 1
      end


      def get_linux_dev_path
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        @os_devpath = "/dev/disk/by-path/ip-%s-iscsi-%s-lun-%d" % ["#{@vol[:storage_node][:ipaddr]}:3260",
                                                                      @vol[:transport_information][:iqn],
                                                                      @vol[:transport_information][:lun]]
      end

      def setup_metadata_drive
        logger.info("Setting up metadata drive image for :#{@hva_ctx.inst_id}")
        # truncate creates sparsed file.
        sh("/usr/bin/truncate -s 10m '#{@hva_ctx.metadata_img_path}'; sync;")
        # TODO: need to lock loop device not to use same device from
        # another thread/process.
        lodev=`/sbin/losetup -f`.chomp
        sh("/sbin/losetup #{lodev} '#{@hva_ctx.metadata_img_path}'")
        sh("mkfs.vfat -n METADATA '#{@hva_ctx.metadata_img_path}'")
        Dir.mkdir("#{@hva_ctx.inst_data_dir}/tmp") unless File.exists?("#{@hva_ctx.inst_data_dir}/tmp")
        sh("/bin/mount -o iocharset=utf8 -t vfat #{lodev} '#{@hva_ctx.inst_data_dir}/tmp'")

        vnic = @inst[:instance_nics].first || {}
        # Appendix B: Metadata Categories
        # http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?AESDG-chapter-instancedata.html
        metadata_items = {
          'ami-id' => @inst[:image][:uuid],
          'ami-launch-index' => 0,
          'ami-manifest-path' => nil,
          'ancestor-ami-ids' => nil,
          'block-device-mapping/root' => '/dev/sda',
          'hostname' => @inst[:hostname],
          'instance-action' => @inst[:state],
          'instance-id' => @inst[:uuid],
          'instance-type' => @inst[:instance_spec][:uuid],
          'kernel-id' => nil,
          'local-hostname' => @inst[:hostname],
          'local-ipv4' => @inst[:ips].first,
          'mac' => vnic[:mac_addr].unpack('A2'*6).join(':'),
          'placement/availability-zone' => nil,
          'product-codes' => nil,
          'public-hostname' => @inst[:hostname],
          'public-ipv4'    => @inst[:nat_ips].first,
          'ramdisk-id' => nil,
          'reservation-id' => nil,
          'security-groups' => @inst[:security_groups].join(' '),
        }

        @inst[:vif].each { |vnic|
          netaddr  = IPAddress::IPv4.new("#{vnic[:ipv4][:network][:ipv4_network]}/#{vnic[:ipv4][:network][:prefix]}")

          # vfat doesn't allow folder name including ":".
          # folder name including mac address replaces "-" to ":".
          mac = vnic[:mac_addr].unpack('A2'*6).join('-')
          metadata_items.merge!({
            "network/interfaces/macs/#{mac}/local-hostname" => @inst[:hostname],
            "network/interfaces/macs/#{mac}/local-ipv4s" => vnic[:ipv4][:address],
            "network/interfaces/macs/#{mac}/mac" => vnic[:mac_addr].unpack('A2'*6).join(':'),
            "network/interfaces/macs/#{mac}/public-hostname" => @inst[:hostname],
            "network/interfaces/macs/#{mac}/public-ipv4s" => vnic[:ipv4][:nat_address],
            "network/interfaces/macs/#{mac}/security-groups" => @inst[:security_groups].join(' '),
            # wakame-vdc extention items.
            # TODO: need an iface index number?
            "network/interfaces/macs/#{mac}/x-gateway" => vnic[:ipv4][:network][:ipv4_gw],
            "network/interfaces/macs/#{mac}/x-netmask" => netaddr.prefix.to_ip,
            "network/interfaces/macs/#{mac}/x-network" => vnic[:ipv4][:network][:ipv4_network],
            "network/interfaces/macs/#{mac}/x-broadcast" => netaddr.broadcast,
            "network/interfaces/macs/#{mac}/x-metric" => vnic[:ipv4][:network][:metric],
          })
        }

        if @inst[:ssh_key_data]
          metadata_items.merge!({
            "public-keys/0=#{@inst[:ssh_key_data][:name]}" => @inst[:ssh_key_data][:public_key],
            'public-keys/0/openssh-key'=> @inst[:ssh_key_data][:public_key],
          })
        else
          metadata_items.merge!({'public-keys/'=>nil})
        end

        # build metadata directory tree
        metadata_base_dir = File.expand_path("meta-data", "#{@hva_ctx.inst_data_dir}/tmp")
        FileUtils.mkdir_p(metadata_base_dir)
        
        metadata_items.each { |k, v|
          if k[-1,1] == '/' && v.nil?
            # just create empty folder
            FileUtils.mkdir_p(File.expand_path(k, metadata_base_dir))
            next
          end
          
          dir = File.dirname(k)
          if dir != '.'
            FileUtils.mkdir_p(File.expand_path(dir, metadata_base_dir))
          end
          File.open(File.expand_path(k, metadata_base_dir), 'w') { |f|
            f.puts(v.to_s)
          }
        }
        # user-data
        File.open(File.expand_path('user-data', "#{@hva_ctx.inst_data_dir}/tmp"), 'w') { |f|
          f.puts(@inst[:user_data])
        }
        
      ensure
        # ignore any errors from cleanup work.
        sh("/bin/umount -f '#{@hva_ctx.inst_data_dir}/tmp'") rescue logger.warn($!.message)
        sh("/sbin/losetup -d #{lodev}") rescue logger.warn($!.message)
      end

      job :run_local_store, proc {
        @inst_id = request.args[0]
        logger.info("Booting #{@inst_id}")

        @inst = rpc.request('hva-collector', 'get_instance',  @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc
        select_hypervisor

        # create hva context
        @hva_ctx = HvaContext.new(self)

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})
        # setup vm data folder
        inst_data_dir = @hva_ctx.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)
        # copy image file
        img_src = @inst[:image][:source]
        @os_devpath = File.expand_path("#{@inst[:uuid]}", inst_data_dir)

        # vmimage cache
        vmimg_cache_dir = File.expand_path("_base", @node.manifest.config.vm_data_dir)
        FileUtils.mkdir_p(vmimg_cache_dir) unless File.exists?(vmimg_cache_dir)
        vmimg_basename = File.basename(img_src[:uri])
        vmimg_cache_path = File.expand_path(vmimg_basename, vmimg_cache_dir)

        logger.debug("preparing #{@os_devpath}")

        # vmimg cached?
        unless File.exists?(vmimg_cache_path)
          logger.debug("copying #{img_src[:uri]} to #{vmimg_cache_path}")
          pararell_curl("#{img_src[:uri]}", "#{vmimg_cache_path}")
        else
          md5sum = sh("md5sum #{vmimg_cache_path}")
          if md5sum[:stdout].split(' ')[0] == @inst[:image][:md5sum]
            logger.debug("verified vm cache image: #{vmimg_cache_path}")
          else
            logger.debug("not verified vm cache image: #{vmimg_cache_path}")
            sh("rm -f %s", [vmimg_cache_path])
            tmp_id = Isono::Util::gen_id
            logger.debug("copying #{img_src[:uri]} to #{vmimg_cache_path}")
            pararell_curl("#{img_src[:uri]}", "#{vmimg_cache_path}.#{tmp_id}")

            sh("mv #{vmimg_cache_path}.#{tmp_id} #{vmimg_cache_path}")
            logger.debug("vmimage cache deployed on #{vmimg_cache_path}")
          end
        end

        ####
        logger.debug("copying #{vmimg_cache_path} to #{@os_devpath}")
        case vmimg_cache_path
        when /\.gz$/
          sh("zcat %s | cp --sparse=always /dev/stdin %s",[vmimg_cache_path, @os_devpath])
        else
          sh("cp -p --sparse=always %s %s",[vmimg_cache_path, @os_devpath])
        end

        sleep 1

        setup_metadata_drive
        
        check_interface
        @hv.run_instance(@hva_ctx)
        update_instance_state({:state=>:running}, 'hva/instance_started')
      }, proc {
        terminate_instance(false) rescue logger.error($!)
        update_instance_state({:state=>:terminated, :terminated_at=>Time.now.utc},
                              'hva/instance_terminated')
      }

      job :run_vol_store, proc {
        @inst_id = request.args[0]
        @vol_id = request.args[1]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Booting #{@inst_id}")
        raise "Invalid instance state: #{@inst[:state]}" unless %w(pending failingover).member?(@inst[:state].to_s)

        # select hypervisor :kvm, :lxc
        select_hypervisor

        # create hva context
        @hva_ctx = HvaContext.new(self)

        rpc.request('hva-collector', 'update_instance', @inst_id, {:state=>:starting})

        # setup vm data folder
        inst_data_dir = @hva_ctx.inst_data_dir
        FileUtils.mkdir(inst_data_dir) unless File.exists?(inst_data_dir)

        # reload volume info
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        
        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        logger.info("Attaching #{@vol_id} on #{@inst_id}")
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        # attach disk
        attach_volume_to_host
        
        setup_metadata_drive
        
        # run vm
        check_interface
        @hv.run_instance(@hva_ctx)
        update_instance_state({:state=>:running}, 'hva/instance_started')
        update_volume_state({:state=>:attached, :attached_at=>Time.now.utc}, 'hva/volume_attached')
      }, proc {
        # TODO: Run detach & destroy volume
        update_instance_state({:state=>:terminated, :terminated_at=>Time.now.utc},
                              'hva/instance_terminated')
        terminate_instance(false) rescue logger.error($!)
        update_volume_state({:state=>:deleted, :deleted_at=>Time.now.utc},
                              'hva/volume_deleted')
      }

      job :terminate do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        begin
          rpc.request('hva-collector', 'update_instance',  @inst_id, {:state=>:shuttingdown})
          terminate_instance(true)
        ensure
          update_instance_state({:state=>:terminated,:terminated_at=>Time.now.utc},
                                'hva/instance_terminated')
        end
      end

      # just do terminate instance and unmount volumes. it should not change
      # state on any resources.
      # called from HA at which the faluty instance get cleaned properly.
      job :cleanup do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        begin
          terminate_instance(false)
        ensure
          # just publish "hva/instance_terminated" to update security group rules once
          update_instance_state({}, 'hva/instance_terminated')
        end
      end

      # stop instance is mostly similar to terminate_instance. the
      # difference is the state transition of instance and associated
      # resources to the instance , attached volumes and vnic, are kept
      # same sate.
      job :stop do
        @inst_id = request.args[0]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        raise "Invalid instance state: #{@inst[:state]}" unless @inst[:state].to_s == 'running'

        select_hypervisor

        begin
          rpc.request('hva-collector', 'update_instance',  @inst_id, {:state=>:stopping})
          terminate_instance(false)
        ensure
          # 
          update_instance_state({:state=>:stopped, :host_node_id=>nil}, 'hva/instance_terminated')
        end
      end

      job :attach, proc {
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Attaching #{@vol_id}")
        raise "Invalid volume state: #{@vol[:state]}" unless @vol[:state].to_s == 'available'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:attaching, :attached_at=>nil})
        # check under until the dev file is created.
        # /dev/disk/by-path/ip-192.168.1.21:3260-iscsi-iqn.1986-03.com.sun:02:a1024afa-775b-65cf-b5b0-aa17f3476bfc-lun-0
        get_linux_dev_path

        # attach disk on host os
        attach_volume_to_host

        logger.info("Attaching #{@vol_id} on #{@inst_id}")

        # attach disk on guest os
        pci_devaddr=nil
        tryagain do
          pci_devaddr = @hv.attach_volume_to_guest(HvaContext.new(self))
        end
        raise "Can't attach #{@vol_id} on #{@inst_id}" if pci_devaddr.nil?

        rpc.request('sta-collector', 'update_volume', @vol_id, {
                      :state=>:attached,
                      :attached_at=>Time.now.utc,
                      :guest_device_name=>pci_devaddr})
        event.publish('hva/volume_attached', :args=>[@inst_id, @vol_id])
        logger.info("Attached #{@vol_id} on #{@inst_id}")
      }, proc {
        # TODO: Run detach volume
        # push back volume state to available.
        update_volume_state({:state=>:available},
                            'hva/volume_available')
        logger.error("Attach failed: #{@vol_id} on #{@inst_id}")
      }

      job :detach do
        @inst_id = request.args[0]
        @vol_id = request.args[1]

        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)
        @vol = rpc.request('sta-collector', 'get_volume', @vol_id)
        logger.info("Detaching #{@vol_id} on #{@inst_id}")
        raise "Invalid volume state: #{@vol[:state]}" unless @vol[:state].to_s == 'attached'

        # select hypervisor :kvm, :lxc
        select_hypervisor

        rpc.request('sta-collector', 'update_volume', @vol_id, {:state=>:detaching, :detached_at=>nil})
        # detach disk on guest os
        tryagain do
          @hv.detach_volume_from_guest(HvaContext.new(self))
        end

        # detach disk on host os
        detach_volume_from_host
        update_volume_state_to_available
      end

      job :reboot, proc {
        @inst_id = request.args[0]
        @inst = rpc.request('hva-collector', 'get_instance', @inst_id)

        # select_hypervisor :kvm, :lxc
        select_hypervisor

        # reboot instance
        @hv.reboot_instance(HvaContext.new(self))
      }

      def rpc
        @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
      end

      def jobreq
        @jobreq ||= Isono::NodeModules::JobChannel.new(@node)
      end

      def event
        @event ||= Isono::NodeModules::EventChannel.new(@node)
      end

      def pararell_curl(url, output_path)
        script_root_path = File.join(File.expand_path('../../../../',__FILE__), 'script')
        sh("#{script_root_path}/pararell-curl.sh --url=#{url} --output_path=#{output_path}")
      end
    end

    class HvaContext

      def initialize(hvahandler)
        raise "Invalid Class: #{hvahandler}" unless hvahandler.instance_of?(HvaHandler)
        @hva = hvahandler
      end

      def node
        @hva.instance_variable_get(:@node)
      end

      def inst_id
        @hva.instance_variable_get(:@inst_id)
      end

      def inst
        @hva.instance_variable_get(:@inst)
      end

      def os_devpath
        @hva.instance_variable_get(:@os_devpath)
      end

      def metadata_img_path
        File.expand_path('metadata.img', inst_data_dir)
      end

      def vol
        @hva.instance_variable_get(:@vol)
      end

      def inst_data_dir
        File.expand_path("#{inst_id}", node.manifest.config.vm_data_dir)
      end
    end

  end
end
