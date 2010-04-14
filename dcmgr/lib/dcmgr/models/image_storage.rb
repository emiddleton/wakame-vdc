module Dcmgr
  module Models
    class ImageStorage < Base
      set_dataset :image_storages
      set_prefix_uuid 'IS'
      
      many_to_one :image_storage_host
      
      many_to_one :account
      many_to_one :user
      
      many_to_many :tags, :join_table=>:tag_mappings, :left_key=>:target_id, :conditions=>{:target_type=>TagMapping::TYPE_IMAGE_STORAGE}
    end
  end
end