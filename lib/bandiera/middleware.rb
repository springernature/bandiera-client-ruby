require 'macmillan/utils'

module Bandiera
  ##
  # Rack middleware for talking to a Bandiera feature flagging service.
  #
  # The benefit of using this middleware is two-fold when working with a Bandiera server:
  #
  # 1. Performance - Using this middleware, you will only call the Bandiera server once per-request (in contrast to using the `enabled?` method where you will make one request per-use).
  # 2. Better Quality Code - If you use the more advanced features in Bandiera (user groups and percentages) you will no longer need to pass around user objects and UUIDs in your code.  This does assume the use of other middlewares to supply user objects and UUIDs though.
  #
  # This middleware can be used in conjunction with the {Macmillan::Utils::Middleware::Uuid} (or one of your own design) to automatically generate UUIDs for your users. See https://github.com/springernature/bandiera/wiki for more information on this approach.
  #
  # @since 3.0.0
  #
  class Middleware
    ##
    # Builds a new instance of Bandiera::Middleware
    #
    # @param app The rack application
    # @param [Hash] opts Additional options for the middleware
    # @option opts [Bandiera::Client] :client The Bandiera::Client class to use
    # @option opts [Array] :groups ([]) The feature flag groups to request and store in the rack env
    # @option opts [String] :uuid_env_key (Macmillan::Utils::Middleware::Uuid.env_key) The rack env key containing a UUID for your current user (to pass to `user_id` in Bandiera)
    # @option opts [String] :user_env_key ('current_user') The rack env key containing your currently logged in user
    # @option opts [Symbol] :user_group_method (:email) The method to call on the current user to pass to `user_group` in Bandiera
    #
    # @see Bandiera::Client
    # @see Macmillan::Utils::Middleware::Uuid
    #
    def initialize(app, opts = {})
      @app               = app
      @client            = opts[:client]
      @groups            = opts[:groups] || []
      @uuid_env_key      = opts[:uuid_env_key] || Macmillan::Utils::Middleware::Uuid.env_key
      @user_env_key      = opts[:user_env_key] || 'current_user'
      @user_group_method = opts[:user_group_method] || :email

      fail ArgumentError, 'You must supply a Bandiera::Client' unless @client
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
