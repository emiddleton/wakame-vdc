require File.dirname(__FILE__) + '/spec_helper'

describe Dcmgr::PhysicalHostScheduler do
  it "should split layer tag names" do
    # tag input: A.1.., B.2, B.1. =>n
    #  [{"A"=>[0],"B"=>[1,2]}, {"1"=>[0,2],"2"=>[1]}, {""=>[0,1,2]}]
    
    objs = Array.new(3).collect{ Object.new }
    
    layers, hosts = Dcmgr::PhysicalHostScheduler::
      Algorithm1::ArrangeHost.layers(["A.1..", "B.2", "B.1."],
                                     objs, 3)
    layers.length.should == 3
    
    layers[0].has_key? "A".should be_true
    layers[0]["A"].should == [0]
    layers[0].has_key? "B".should be_true
    layers[0]["B"].should == [1,2]
    
    layers[1].has_key? "1".should be_true
    layers[1]["1"].should == [0,2]
    layers[1].has_key? "2".should be_true
    layers[1]["2"].should == [1]
    
    layers[2].has_key? "".should be_true
    layers[2][""].should == [0,1,2]

    a, b, c = hosts
    
    a.same_area_hosts(0).should == []
    a.same_area_hosts(1).should == [c]
    a.same_area_hosts(2).should == [b, c]
    
    b.same_area_hosts(0).should == [c]
    b.same_area_hosts(1).should == []
    b.same_area_hosts(2).should == [a, c]
    
    c.same_area_hosts(0).should == [b]
    c.same_area_hosts(1).should == [a]
    c.same_area_hosts(2).should == [a, b]
  end
end

