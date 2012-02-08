# -*- coding: utf-8 -*-

module Dcmgr::Models
  class TagMapping < BaseNew(:tag_mappings)
    many_to_one :tag
  end
end

