# -*- coding: utf-8 -*-

require File.dirname(__FILE__) + '/spec_helper'

describe User do
  before(:all) do
    @user_a = User.create(:name=>'user a')
    @user_b = User.create(:name=>'user b')
    @user_b.enable = 'n'
    @user_b.save
  end

  it "should default user fields" do
    @user_a.enable.should == 'y'
    @user_a.enable?.should be_true
    @user_b.enable.should == 'n'
    @user_b.enable?.should be_false
  end
    
  it "should be get only enable users" do
    User.all.index{|u| u.id == @user_a.id}.should be_true
    User.all.index{|u| u.id == @user_b.id}.should be_nil
  end
end