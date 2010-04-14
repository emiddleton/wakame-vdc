
module Dcmgr
  module Helpers
    def logger
      Dcmgr.logger
    end

    def json_request(request)
      ret = Hash.new

      if request.respond_to? :GET
        request.GET.each{|k,v|
          ret[:"_get_#{k}"] = v
        }
      
        if request.respond_to? :content_length and request.content_length.to_i > 0
          body = request.body.read
          parsed = JSON.parse(body)
          Dcmgr.logger.debug("request: " + parsed.inspect)
          
          parsed.each{|k,v|
            ret[k.to_sym] = v
          }
        end
        
      else
        request.each{|k,v|
          ret[k.to_sym] = v
        }
      end
      
      logger.debug "request: #{ret.inspect}"

      ret
    end
  end

  module UUIDAuthorizeHelpers
    def protected!
      authorized?
    end

    def authorized?
      @fsuser = Dcmgr::FsuserAuthorizer.authorize(request)
      user_uuid = request.env['HTTP_X_WAKAME_USER']
      if user_uuid
        user = authorize(user_uuid)
      else
        false
      end
    rescue Dcmgr::FsuserAuthorizer::NotAuthorized
      throw(:halt, [401, "Not authorized\n"])
    end

    def authorize(uuid, password=nil)
      @user = Models::User[uuid].tap{|user|
        Models::Log.create(:fsuser=>@fsuser,
                           :target_uuid=>user.uuid,
                           :user_id=>user.id,
                           :account_id=>0,
                           :action=>'login')
      }
    rescue Dcmgr::Models::InvalidUUIDError => e
      raise Dcmgr::FsuserAuthorizer::NotAuthorized.new
    end

    def authorized_user
      @user
    end
  end
  
  module BasicAuthorizeHelpers
    def protected!
      response['WWW-Authenticate'] = %(Basic realm="HTTP Auth") and
        throw(:halt, [401, "Not authorized\n"]) and
        return unless authorized?
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? &&
        authorize(@auth.credentials, @auth.credentials)
    end

    def authorize(name, password)
      @user = User.find(:name=>name, :password=>password)
      @user
    end

    def authorized_user
      @user
    end
  end
  
  module NoAuthorizeHelpers
    def protected!
      true
    end
    
    def authorized?
      true
    end
    
    def authorize(name, password)
      true
    end

    def authorized_user
      nil
    end
  end
end