require 'macmillan/utils'

module Bandiera
  class Middleware
    def initialize(app,
                   client:,
                   groups:            [],
                   uuid_env_key:      Macmillan::Utils::Middleware::Uuid.env_key,
                   user_env_key:      'user.user',
                   user_env_key:      'current_user',
                   user_group_method: :email)
      @app               = app
      @client            = client
      @groups            = groups
      @uuid_env_key      = uuid_env_key
      @user_env_key      = user_env_key
      @user_group_method = user_group_method
    end

    def call(env)
      dup.process(env)
    end

    def process(env)
      request = Rack::Request.new(env)

      user       = request.env[@user_env_key]
      user_group = user ? user.public_send(@user_group_method) : nil
      uuid       = request.env[@uuid_env_key]

      if @groups.empty?
        @client.get_all(user_group: user_group, user_id: uuid).each do |group, flags|
          request.env["bandiera.#{group}"] = flags
        end
      else
        @groups.each do |group|
          request.env["bandiera.#{group}"] = @client.get_features_for_group(group, user_group: user_group, user_id: uuid)
        end
      end

      @app.call(request.env)
    end
  end
end
