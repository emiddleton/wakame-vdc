# -*- coding: utf-8 -*-

module Dcmgr::Cli
  class SecurityGroup < Base
    namespace :securitygroup
    M = Dcmgr::Models

    no_tasks {
      def read_rule_text
        if options[:rule].nil?
          # Set blank string as rule.
          return ''
        elsif options[:rule] == '-'
          # Read from STDIN
          STDIN.read
        else
          # Read from file.
          raise "Unknown rule file: #{options[:rule]}" if !File.exists?(options[:rule])
          File.read(options[:rule])
        end
      end
    }

    desc "add [options]", "Add a new security group"
    method_option :uuid, :type => :string, :desc => "The UUID for the new security group."
    method_option :account_id, :type => :string, :desc => "The UUID of the account this security group belongs to.", :required => true
    method_option :description, :type => :string, :desc => "The description for this new security group."
    method_option :rule, :type => :string, :desc => "Path to the rule text file. (\"-\" is from STDIN)"
    def add
      UnknownUUIDError.raise(options[:account_id]) if M::Account[options[:account_id]].nil?

      fields = options.dup
      fields[:rule] = read_rule_text
      
      puts super(M::SecurityGroup,fields)
    end
    
    desc "del UUID", "Delete a security group"
    def del(uuid)
      super(M::SecurityGroup,uuid)
    end
    
    desc "show [UUID]", "Show security group(s)"
    def show(uuid=nil)
      if uuid
        group = M::SecurityGroup[uuid] || UnknownUUIDError.raise(uuid)
        puts ERB.new(<<__END, nil, '-').result(binding)
Group UUID:
  <%= group.canonical_uuid %>
Account id:
  <%= group.account_id %>
<%- if group.description -%>
Description:
  <%= group.description %>
<%- end -%>
<%- unless group.security_group_rules.empty? -%>
Rules:
<%- group.security_group_rules.each { |rule| -%>
  <%= rule.permission %>
<%- } -%>
<%- end -%>
__END
      else
        puts ERB.new(<<__END, nil, '-').result(binding)
<%- M::SecurityGroup.all { |row| -%>
<%= row.canonical_uuid %>\t<%= row.account_id %>\t<%= row.description %>
<%- } -%>
__END
      end
    end
    
    desc "modify UUID [options]", "Modify an existing security group"
    method_option :account_id, :type => :string, :desc => "The UUID of the account this security group belongs to."
    method_option :description, :type => :string, :desc => "The description for this new security group."
    method_option :rule, :type => :string, :desc => "Path to the rule text file. (\"-\" is from STDIN)"
    def modify(uuid)
      UnknownUUIDError.raise(options[:account_id]) if options[:account_id] && M::Account[options[:account_id]].nil?

      fields = options.dup
      if options[:rule]
        fields[:rule] = read_rule_text
      end
      
      super(M::SecurityGroup,uuid, fields)
    end
    
    desc "apply UUID [options]", "Apply a security group to an instance"
    method_option :instance, :type => :string, :required => :true, :desc => "The instance to apply the group to"
    def apply(uuid)
      group = M::SecurityGroup[uuid] || UnknownUUIDError.raise(uuid)
      instance = M::Instance[options[:instance]] || UnknownUUIDError.raise(options[:instance])
      Error.raise("Group #{uuid} is already applied to instance #{options[:instance]}.",100) if group.instances.member?(instance)
      group.add_instance(instance)
    end
    
    desc "remove UUID [options]", "Remove a security group from an instance"
    method_option :instance, :type => :string, :required => :true, :desc => "The instance to remove the group from"
    def remove(uuid)
      group = M::SecurityGroup[uuid] || UnknownUUIDError.raise(uuid)
      instance = M::Instance[options[:instance]] || UnknownUUIDError.raise(options[:instance])
      Error.raise("Group #{uuid} is not applied to instance #{options[:instance]}.",100) unless group.instances.member?(instance)
      group.remove_instance(instance)
    end
    
  end
end
