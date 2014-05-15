require 'rest_client'
require 'json'

# TODO: add some intelligent way of using the bulk endpoints...

module Bandiera
  class Client
    class RequestError < StandardError; end
    class ServerDownError < StandardError; end
    class TimeOutError < StandardError; end

    HANDLED_EXCEPTIONS = [RequestError, ServerDownError, TimeOutError]

    attr_accessor :timeout
    attr_reader :logger

    def initialize(base_uri = 'http://localhost', logger = Logger.new($stdout), client_name = nil)
      @base_uri    = base_uri
      @logger      = logger
      @timeout     = 0.02 # 20ms default timeout
      @client_name = client_name

      @base_uri << '/api' unless @base_uri.match(/\/api$/)
    end

    def enabled?(group, feature, params = { user_group: nil })
      get_feature(group, feature, params)
    end

    private

    def headers
      headers = {
        'User-Agent' => "Bandiera Ruby Client / #{Bandiera::Client::VERSION}"
      }
      headers.merge! 'Bandiera-Client' => @client_name unless @client_name.nil?
      headers
    end

    def get_feature(group, feature, params)
      path             = "/v2/groups/#{group}/features/#{feature}"
      default_response = false
      error_msg_prefix = "[Bandiera::Client#get_feature] '#{group} / #{feature} / #{params}'"

      get_and_handle_exceptions(path, params, default_response, error_msg_prefix)
    end

    def get_features_for_group(group, params)
      path             = "/v2/groups/#{group}/features"
      default_response = {}
      error_msg_prefix = "[Bandiera::Client#get_features_for_group] '#{group} / #{params}'"

      get_and_handle_exceptions(path, params, default_response, error_msg_prefix)
    end

    def get_all(params)
      path             = '/v2/all'
      default_response = {}
      error_msg_prefix = "[Bandiera::Client#get_all] '#{params}'"

      get_and_handle_exceptions(path, params, default_response, error_msg_prefix)
    end

    def get_and_handle_exceptions(path, params, return_upon_error, error_msg_prefix)
      res = get(path, params)
      logger.warn "#{error_msg_prefix} - #{res['warning']}" if res['warning']
      res['response']
    rescue *HANDLED_EXCEPTIONS => error
      logger.warn("#{error_msg_prefix} - #{error.message}")
      return_upon_error
    end

    def get(path, params)
      url     = "#{@base_uri}#{path}"
      client_headers = headers.merge params: clean_params(params)
      client_params = {
        method:       :get,
        url:          url,
        timeout:      timeout,
        open_timeout: timeout,
        headers:      client_headers
      }
      request = RestClient::Request.new client_params
      response = request.execute
      JSON.parse response.body
    rescue RestClient::RequestTimeout
      raise TimeOutError, "Timeout occured requesting '#{url}'"
    rescue RestClient::ServerBrokeConnection
      raise ServerDownError, 'Bandiera appears to be down.'
    rescue => e
      raise RequestError, "Error #{e.message}.\nGET request to '#{url}' returned #{response.inspect}"
    end

    def clean_params(passed_params)
      params = {}

      passed_params.each do |key, val|
        params[key] = val unless val.nil? || val.empty?
      end

      params
    end
  end
end
