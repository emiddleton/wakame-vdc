# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class KeyPair < Base
    namespace :keypair
    M = Dcmgr::Models
    include Dcmgr::Helpers::CliHelper

    desc "add [options]", "Register a new key pair."
    method_option :uuid, :type => :string, :desc => "The UUID for the new key pair"
    method_option :account_id, :type => :string, :desc => "The UUID of the account this key pair belongs to", :required => true
    method_option :public_key, :type => :string, :desc => "The path to the public key", :required => true
    method_option :private_key, :type => :string, :desc => "The path to the private key"
    method_option :description, :type => :string, :desc => "Description for this key pair"
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?
      private_key_path = File.expand_path(options[:private_key])
      public_key_path = File.expand_path(options[:public_key])
      Error.raise "Private key file doesn't exist",100 unless File.exists?(private_key_path) || options[:private_key]
      Error.raise "Public key file doesn't exist",100 unless File.exists?(public_key_path)
      
      fields = options.dup
      
      #Get the keys from their respective files.
      fields[:public_key] = File.open(public_key_path) {|f| f.readline}
      fields[:private_key] = File.open(private_key_path) {|f| f.readlines.join('') }
      
      #Generate the fingerprint from the public key file
      res = sh("ssh-keygen -lf #{options[:public_key]}")
      fields[:finger_print] = res[:stdout].split(' ')[1]
      
      puts super(M::SshKeyPair,fields)
    end
    
    desc "modify UUID [options]", "Modify an existing key pair"
    method_option :account_id, :type => :string, :desc => "The UUID of the account this key pair belongs to"
    method_option :description, :type => :string, :desc => "Description for this key pair"
    def modify(uuid)
      UnknownUUIDError.raise(options[:account_id]) if options[:account_id] && M::Account[options[:account_id]].nil?
      super(M::SshKeyPair,uuid,options)
    end
    
    desc "del UUID", "Delete an existing keypair"
    def del(uuid)
      super(M::SshKeyPair,uuid)
    end
    
    desc "show [UUID] [options]", "Show network(s)"
    def show(uuid=nil)
      if uuid
        keypair = M::SshKeyPair[uuid] || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
Keypair UUID:
  <%= keypair.canonical_uuid %>
Account id:
  <%= keypair.account_id %>
Finger print:
  <%= keypair.finger_print %>
Public Key:
  <%= keypair.public_key%>
<%- if keypair.description -%>
Description:
  <%= keypair.description %>
<%- end -%>
__END
      else
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- M::SshKeyPair.each { |row| -%>
<%= row.canonical_uuid %>\t<%= row.account_id %>\t<%= row.finger_print %>
<%- } -%>
__END
      end
    end
    
  end
end
