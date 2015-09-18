require 'rest_client'
require 'json'
require 'logger'

module Bandiera
  class Client
    autoload :VERSION, 'bandiera/client/version'

    attr_accessor :timeout, :client_name
    attr_reader :logger

    def initialize(base_uri = 'http://localhost', logger = Logger.new($stdout), client_name = nil)
      @base_uri       = base_uri
      @base_uri       << '/api' unless @base_uri.match(/\/api$/)
      @logger         = logger
      @timeout        = 0.2 # 0.4s (0.2 + 0.2) default timeout
      @client_name    = client_name
    end

    def cache_strategy=(_)
      warn 'The caching features in Bandiera::Client have been removed as of v3.0.0, please consider using using ' \
           'the Bandiera::Middleware class shipped as part of the "bandiera-client" gem.'
    end

    def get_feature(group, feature, params = {}, http_opts = {})
      path             = "/v2/groups/#{group}/features/#{feature}"
      default_response = false
      error_msg_prefix = "[Bandiera::Client#get_feature] '#{group} / #{feature} / #{params}'"

      logger.debug "[Bandiera::Client#get_feature] calling #{path} with params: #{params}"

      get_and_handle_exceptions(path, params, http_opts, default_response, error_msg_prefix)
    end

    alias_method :enabled?, :get_feature

    def get_features_for_group(group, params = {}, http_opts = {})
      path             = "/v2/groups/#{group}/features"
      default_response = {}
      error_msg_prefix = "[Bandiera::Client#get_features_for_group] '#{group} / #{params}'"

      logger.debug "[Bandiera::Client#get_features_for_group] calling #{path} with params: #{params}"

      get_and_handle_exceptions(path, params, http_opts, default_response, error_msg_prefix)
    end

    def get_all(params = {}, http_opts = {})
      path             = '/v2/all'
      default_response = {}
      error_msg_prefix = "[Bandiera::Client#get_all] '#{params}'"

      logger.debug "[Bandiera::Client#get_all] calling #{path} with params: #{params}"

      get_and_handle_exceptions(path, params, http_opts, default_response, error_msg_prefix)
    end

    private

    def headers
      headers = { 'User-Agent' => "Bandiera Ruby Client / #{Bandiera::Client::VERSION}" }
      headers.merge!('Bandiera-Client' => client_name) unless client_name.nil?
      headers
    end

    EXCEPTIONS_TO_HANDLE = (
      Errno.constants.map { |cla| Errno.const_get(cla) } + [RestClient::Exception, JSON::ParserError]
    ).flatten

    def get_and_handle_exceptions(path, params, http_opts, return_upon_error, error_msg_prefix, &block)
      res = get(path, params, http_opts)
      logger.warn "#{error_msg_prefix} - #{res['warning']}" if res['warning']
      block.call(res['response']) if block
      res['response']
    rescue *EXCEPTIONS_TO_HANDLE => error
      logger.warn("#{error_msg_prefix} - #{error.class} - #{error.message}")
      return_upon_error
    end

    def get(path, params, passed_http_opts)
      default_http_opts = { method: :get, timeout: timeout, open_timeout: timeout, headers: headers }
      resource          = RestClient::Resource.new(@base_uri, default_http_opts.merge(passed_http_opts))
      response          = resource[path].get(params: clean_params(params))

      JSON.parse(response.body)
    end

    def clean_params(passed_params)
      params = {}

      passed_params.each do |key, val|
        params[key] = val unless val.nil? || (val.respond_to?(:empty) && val.empty?)
      end

      params
    end
  end
end
