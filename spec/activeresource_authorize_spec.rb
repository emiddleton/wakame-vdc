# -*- coding: utf-8 -*-

require 'rubygems'
require File.dirname(__FILE__) + '/spec_helper'

describe "active resource authorization" do
  include ActiveResourceHelperMethods
  before(:all) do
    @authuser = User.create(:account=>'__test_auth__', :password=>'passwd')
  end

  it "should not authorize" do
    lambda {
      not_auth_tag_class = describe_activeresource_model :NameTag, '__test_auth__', 'bad_passwd'
      not_auth_tag_class.create(:name=>'name tag',
                                :account=>@account)
    }.should raise_error(ActiveResource::UnauthorizedAccess)
  end
  
  it "should authorize" do
    auth_tag_class = describe_activeresource_model :NameTag, '__test_auth__', 'passwd'
    tag = auth_tag_class.create(:name=>'name tag',
                                :account=>@account)
    tag.id.length.should > 0
  end
end

