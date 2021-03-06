# -*- coding: utf-8 -*-

module Dcmgr
  module VNet
    module Netfilter
    
      class NetfilterCache < Cache
        include Dcmgr::Logger
        
        def initialize(node)
          # Initialize the values needed to do rpc requests
          @node = node
          @rpc ||= Isono::NodeModules::RpcChannel.new(@node)
        end

        # Makes a call to the database and updates the Cache
        def update
          logger.info "updating cache from database"
          @cache = @rpc.request('hva-collector', 'get_netfilter_data', @node.node_id)
        end
        
        # Returns the cache
        # if _force_update_ is set to true, the cache will be updated from the database
        def get(force_update = false)
          self.update if @cache.nil? || force_update
          
          # Always return a duplicate of the cache. We don't want any external program messing with the original contents.
          #TODO: Do this in a faster way than marshall
          Marshal.load( Marshal.dump(@cache) )
        end
        
        # Adds a newly started instance to the existing cache
        def add_instance(inst_map)
          if @cache.is_a? Hash
            logger.info "adding instance '#{inst_map[:uuid]} to cache'"
            @cache << inst_map
          else
          
          end
        end
        
        # Removes a terminated instance from the existing cache
        def remove_instance(inst_id)
          logger.info "removing Instance '#{inst_id}' from cache"
          @cache[:instances].delete_if {|inst_map| inst_map[:uuid] == inst_id }
        end
      end
    
    end
  end
end
