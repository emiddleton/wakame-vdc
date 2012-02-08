# -*- coding: utf-8 -*-

require 'dcmgr/models/base_new'

module Dcmgr::Models

  # Base class for the model class which belongs to a specific account.
  module AccountResource
    module InstanceMethods
      def account
        Account[self.account_id]
      end
    end
  end
  
  def self.AccountResource(dc)
    klass = BaseNew(dc)
    klass.plugin AccountResource
    klass
  end
end
