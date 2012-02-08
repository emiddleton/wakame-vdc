# -*- coding: utf-8 -*-

module Dcmgr::Models
  # History record table for ArchiveChangedColumn plugin
  class History < BaseNew(:histories)
    plugin :timestamps
    
  end
end
