# -*- coding: utf-8 -*-

module Dcmgr::Models
  class InstanceSecurityGroup < BaseNew(:instance_security_groups)
    many_to_one :instance
    many_to_one :security_group
  end
end
