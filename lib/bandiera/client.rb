require 'rest_client'
require 'json'
require 'logger'
require 'moneta'

module Bandiera
  class Client
    autoload :VERSION, 'bandiera/client/version'

    CACHE_STRATEGIES = [:single_feature, :group, :all]

    attr_accessor :timeout, :client_name, :cache_ttl
    attr_reader :logger, :cache, :cache_strategy

    def initialize(base_uri = 'http://localhost', logger = Logger.new($stdout), client_name = nil)
      @base_uri       = base_uri
      @base_uri       << '/api' unless @base_uri.match(/\/api$/)
      @logger         = logger
      @timeout        = 0.2 # 0.4s (0.2 + 0.2) default timeout
      @client_name    = client_name
      @cache          = Moneta.new(:LRUHash, expires: true)
      @cache_ttl      = 5 # 5 seconds
      @cache_strategy = :group
    end

    def cache_strategy=(strategy)
      unless CACHE_STRATEGIES.include?(strategy)
        raise ArgumentError, "cache_strategy can only be #{CACHE_STRATEGIES}"
      end
      @cache_strategy = strategy
    end

    def enabled?(group, feature, params = {}, http_opts = {})
      cache_key = build_cache_key(group, feature, params)

      unless cache.key?(cache_key)
        case cache_strategy
        when :single_feature then get_feature(group, feature, params, http_opts)
        when :group          then get_features_for_group(group, params, http_opts)
        when :all            then get_all
        end
      end

      cache.fetch(cache_key)
    end

    def get_feature(group, feature, params = {}, http_opts = {})
      path             = "/v2/groups/#{group}/features/#{feature}"
      default_response = false
      error_msg_prefix = "[Bandiera::Client#get_feature] '#{group} / #{feature} / #{params}'"

      logger.debug "[Bandiera::Client#get_feature] calling #{path} with params: #{params}"

      get_and_handle_exceptions(path, params, http_opts, default_response, error_msg_prefix) do |value|
        store_value_in_cache(group, feature, params, value)
      end
    end

    def get_features_for_group(group, params = {}, http_opts = {})
      path             = "/v2/groups/#{group}/features"
      default_response = {}
      error_msg_prefix = "[Bandiera::Client#get_features_for_group] '#{group} / #{params}'"

      logger.debug "[Bandiera::Client#get_features_for_group] calling #{path} with params: #{params}"

      get_and_handle_exceptions(path, params, http_opts, default_response, error_msg_prefix) do |feature_hash|
        store_feature_hash_in_cache(group, params, feature_hash)
      end
    end

    def get_all(params = {}, http_opts = {})
      path             = '/v2/all'
      default_response = {}
      error_msg_prefix = "[Bandiera::Client#get_all] '#{params}'"

      logger.debug "[Bandiera::Client#get_all] calling #{path} with params: #{params}"

      get_and_handle_exceptions(path, params, http_opts, default_response, error_msg_prefix) do |group_hash|
        group_hash.each do |group, feature_hash|
          store_feature_hash_in_cache(group, params, feature_hash)
        end
      end
    end

    private

    def store_feature_hash_in_cache(group, params, feature_hash)
      feature_hash.each do |feature, value|
        store_value_in_cache(group, feature, params, value)
      end
    end

    def store_value_in_cache(group, feature, params, value)
      cache_key = build_cache_key(group, feature, params)
      cache.store(cache_key, value, expires: cache_ttl)
    end

    def build_cache_key(group, feature, params)
      "#{group} / #{feature} / #{params}"
    end

    def headers
      headers = { 'User-Agent' => "Bandiera Ruby Client / #{Bandiera::Client::VERSION}" }
      headers.merge!('Bandiera-Client' => client_name) unless client_name.nil?
      headers
    end

    EXCEPTIONS_TO_HANDLE = (
      Errno.constants.map { |cla| Errno.const_get(cla) } + [RestClient::Exception]
    ).flatten

    def get_and_handle_exceptions(path, params, http_opts, return_upon_error, error_msg_prefix, &block)
      res = get(path, params, http_opts)
      logger.warn "#{error_msg_prefix} - #{res['warning']}" if res['warning']
      block.call(res['response']) if block
      res['response']
    rescue *EXCEPTIONS_TO_HANDLE => error
      logger.warn("#{error_msg_prefix} - #{error.message}")
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
