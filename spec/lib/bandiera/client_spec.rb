require 'spec_helper'

describe Bandiera::Client do
  let(:base_uri)  { 'http://bandiera.com' }
  let(:api_uri)   { "#{base_uri}/api" }
  let(:logger)    { double.as_null_object }
  subject         { Bandiera::Client.new(api_uri, logger) }

  shared_examples_for 'a robust request' do
    context 'bandiera is down' do
      it 'returns a default response' do
        stub_request(:get, url).to_return(status: [0, ''])

        expect(response).to eq expected_error_response
      end
    end

    context 'bandiera is having some problems' do
      it 'returns a default response' do
        stub_request(:get, url).to_return(status: 500, body: '')

        expect(response).to eq expected_error_response
      end
    end

    context 'bandiera times out' do
      it 'returns a default response' do
        stub_request(:get, url).to_timeout

        expect(response).to eq expected_error_response
      end
    end

    context 'bandiera cannot be contacted' do
      it 'returns a default response' do
        stub_request(:get, url).to_raise(::SocketError)

        expect(response).to eq expected_error_response
      end
    end
  end

  context 'when a client name is provided' do
    let(:group)   { 'pubserv' }
    let(:feature) { 'log-stats' }
    let(:url)     { "#{api_uri}/v2/groups/#{group}/features/#{feature}" }

    it 'sends it as part of the headers' do
      stub   = stub_api_request(url, { 'response' => {} }, { 'Bandiera-Client' => 'asdf' })
      client = Bandiera::Client.new(api_uri, logger, 'asdf')
      client.enabled?(group, feature)
      expect(stub).to have_been_requested
    end
  end

  context 'when some Typhoeus::Request options are passed' do
    it 'passes them onto the Typhoeus::Resource' do
      params   = {}
      options  = { timeout: 24, open_timeout: 24 }
      response = double(:response, body: JSON.generate({ response: {} }), success?: true)
      resource = double(:resource, run: response)

      expect(Typhoeus::Request)
        .to receive(:new)
        .with("#{api_uri}/v2/groups/foo/features/bar", method: :get, timeout: 24, open_timeout: 24, headers: {"User-Agent"=>"Bandiera Ruby Client / #{Bandiera::Client::VERSION}"}, params: {})
        .once
        .and_return(resource)

      subject.enabled?('foo', 'bar', params, options)
    end
  end

  context 'raises a Bandiera::Client::Error, Bandiera::Client::TimeoutError or Bandiera::Client::ResponseError if there is a problem' do
    context 'Bandiera::Client::Error' do
      it 'is raised if the response code is 0' do
        params   = {}
        response = double(:response, body: JSON.generate({ response: {} }), success?: false, timed_out?: false, code: 0, return_message: 'test')
        resource = double(:resource, run: response)

        allow(Typhoeus::Request).to receive(:new).and_return(resource)
        expect(logger).to receive(:warn).with('Bandiera::Client - HANDLED EXCEPTION #<Bandiera::Client::Error: test> - CLASS Bandiera::Client::Error')

        subject.enabled?('foo', 'bar', params)
      end
    end

    context 'Bandiera::Client::TimeoutError' do
      it 'is raised if the response is flagged as timed out' do
        params   = {}
        response = double(:response, body: JSON.generate({ response: {} }), success?: false, timed_out?: true)
        resource = double(:resource, run: response)

        allow(Typhoeus::Request).to receive(:new).and_return(resource)
        expect(logger).to receive(:warn).with('Bandiera::Client - HANDLED EXCEPTION #<Bandiera::Client::TimeoutError: Connection timed out> - CLASS Bandiera::Client::TimeoutError')

        subject.enabled?('foo', 'bar', params)
      end
    end

    context 'Bandiera::Client::ResponseError' do
      it 'is raised if the response is flagged as timed out' do
        params   = {}
        response = double(:response, body: JSON.generate({ response: {} }), success?: false, timed_out?: false, code: 404)
        resource = double(:resource, run: response)

        allow(Typhoeus::Request).to receive(:new).and_return(resource)
        expect(logger).to receive(:warn).with('Bandiera::Client - HANDLED EXCEPTION #<Bandiera::Client::ResponseError: HTTP request failed: 404> - CLASS Bandiera::Client::ResponseError')

        subject.enabled?('foo', 'bar', params)
      end
    end
  end

  describe '#get_feature' do
    let(:group)   { 'pubserv' }
    let(:feature) { 'log-stats' }
    let(:url)     { "#{api_uri}/v2/groups/#{group}/features/#{feature}" }
    let(:response) { subject.get_feature(group, feature) }
    let(:expected_error_response) { false }

    context 'all is ok' do
      it 'returns the bandiera response' do
        stub     = stub_api_request(url, 'response' => true)

        expect(response).to be true
        expect(stub).to have_been_requested
      end

      context 'and the user has passed through some extra params' do
        it 'passes them through to the API' do
          stub = stub_request(:get, url)
                   .with(query: { user_group: 'admin', user_id: '12345' })
                   .to_return(
                     body: JSON.generate('response' => true),
                     headers: { 'Content-Type' => 'application/json' }
                   )

          subject.get_feature(group, feature, { user_group: 'admin', user_id: 12345 })

          expect(stub).to have_been_requested
        end
      end

      context 'but bandiera returns a warning along with the response' do
        it 'logs the warning' do
          stub = stub_api_request(url, 'response' => false, 'warning' => 'The group does not exist')

          # 2 calls - one for the request, one for the warning
          expect(logger).to receive(:debug).twice

          expect(response).to be false
          expect(stub).to have_been_requested
        end
      end
    end

    it_behaves_like 'a robust request'

  end

  describe '#get_features_for_group' do
    let(:group) { 'pubserv' }
    let(:url)   { "#{api_uri}/v2/groups/#{group}/features" }
    let(:response) { subject.get_features_for_group(group) }
    let(:expected_error_response) { {} }

    context 'all is ok' do
      it 'returns the bandiera response' do
        feature_hash = { 'show-stuff' => true, 'show-other-stuff' => false }
        stub         = stub_api_request(url, 'response' => feature_hash)

        expect(response).to eq(feature_hash)
        expect(stub).to have_been_requested
      end

      context 'and the user has passed through some extra params' do
        it 'passes them through to the API' do
          stub = stub_request(:get, url)
                   .with(query: { user_group: 'admin', user_id: '12345' })
                   .to_return(
                     body: JSON.generate('response' => {}),
                     headers: { 'Content-Type' => 'application/json' }
                   )

          subject.get_features_for_group(group, { user_group: 'admin', user_id: 12345 })

          expect(stub).to have_been_requested
        end
      end

      context 'but bandiera returns a warning along with the response' do
        it 'logs the warning' do
          stub = stub_api_request(url, 'response' => {}, 'warning' => 'The group does not exist')

          # 2 calls - one for the request, one for the warning
          expect(logger).to receive(:debug).twice

          expect(response).to be {}
          expect(stub).to have_been_requested
        end
      end
    end

    it_behaves_like 'a robust request'
  end

  describe '#get_all' do
    let(:url) { "#{api_uri}/v2/all" }
    let(:response) { subject.get_all }
    let(:expected_error_response) { {} }

    context 'all is ok' do
      it 'returns the bandiera response' do
        feature_hash = { 'pubserv' => { 'show-stuff' => true, 'show-other-stuff' => false } }
        stub         = stub_api_request(url, 'response' => feature_hash)

        expect(response).to eq(feature_hash)
        expect(stub).to have_been_requested
      end

      context 'and the user has passed through some extra params' do
        it 'passes them through to the API' do
          stub = stub_request(:get, url)
                   .with(query: { user_group: 'admin', user_id: '12345' })
                   .to_return(
                     body: JSON.generate('response' => {}),
                     headers: { 'Content-Type' => 'application/json' }
                   )

          subject.get_all({ user_group: 'admin', user_id: 12345 })

          expect(stub).to have_been_requested
        end
      end

      context 'but bandiera returns a warning along with the response' do
        it 'logs the warning' do
          stub = stub_api_request(url, 'response' => {}, 'warning' => 'The group does not exist')

          # 2 calls - one for the request, one for the warning
          expect(logger).to receive(:debug).twice

          expect(response).to be {}
          expect(stub).to have_been_requested
        end
      end
    end

    it_behaves_like 'a robust request'
  end

  private

  def stub_api_request(url, response, headers = {})
    headers.merge! 'User-Agent' => "Bandiera Ruby Client / #{Bandiera::Client::VERSION}"
    stub_request(:get, url)
      .with(headers: headers)
      .to_return(
        body: JSON.generate(response),
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
