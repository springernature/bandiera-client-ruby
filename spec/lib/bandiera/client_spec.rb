require 'spec_helper'

describe Bandiera::Client do
  let(:base_uri)  { 'http://bandiera.com' }
  let(:api_uri)   { "#{base_uri}/api" }
  let(:logger)    { double.as_null_object }
  subject         { Bandiera::Client.new(api_uri, logger) }

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

  context 'when some RestClient::Resource options are passed' do
    it 'passes them onto the RestClient::Resource' do
      params   = {}
      options  = { timeout: 24, open_timeout: 24 }
      response = double(:response, body: JSON.generate({ response: {} }))
      resource = double(:resource, '[]' => double(get: response))

      expect(RestClient::Resource)
        .to receive(:new)
        .with(api_uri, method: :get, timeout: 24, open_timeout: 24, headers: anything)
        .once
        .and_return(resource)

      subject.enabled?('foo', 'bar', params, options)
    end
  end

  describe '#get_feature' do
    let(:group)   { 'pubserv' }
    let(:feature) { 'log-stats' }
    let(:url)     { "#{api_uri}/v2/groups/#{group}/features/#{feature}" }

    context 'all is ok' do
      it 'returns the bandiera response' do
        stub     = stub_api_request(url, 'response' => true)
        response = subject.get_feature(group, feature)

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

          response = subject.get_feature(group, feature)

          expect(response).to be false
          expect(stub).to have_been_requested
        end
      end
    end

    context 'bandiera is down' do
      it 'returns a default response' do
        stub_request(:get, url).to_return(status: [0, ''])

        response = subject.get_feature(group, feature)

        expect(response).to be false
      end
    end

    context 'bandiera is having some problems' do
      it 'returns a default response' do
        stub_request(:get, url).to_return(status: 500, body: '')

        response = subject.get_feature(group, feature)

        expect(response).to be false
      end
    end

    context 'bandiera times out' do
      it 'returns a default response' do
        stub_request(:get, url).to_timeout

        response = subject.get_feature(group, feature)

        expect(response).to be false
      end
    end
  end

  describe '#get_features_for_group' do
    let(:group) { 'pubserv' }
    let(:url)   { "#{api_uri}/v2/groups/#{group}/features" }

    context 'all is ok' do
      it 'returns the bandiera response' do
        feature_hash = { 'show-stuff' => true, 'show-other-stuff' => false }
        stub         = stub_api_request(url, 'response' => feature_hash)
        response     = subject.get_features_for_group(group)

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

          response = subject.get_features_for_group(group)

          expect(response).to be {}
          expect(stub).to have_been_requested
        end
      end
    end

    context 'bandiera is down' do
      it 'returns a default response' do
        stub_request(:get, url).to_return(status: [0, ''])

        response = subject.get_features_for_group(group)

        expect(response).to be {}
      end
    end

    context 'bandiera is having some problems' do
      it 'returns a default response' do
        stub_request(:get, url).to_return(status: 500, body: '')

        response = subject.get_features_for_group(group)

        expect(response).to be {}
      end
    end

    context 'bandiera times out' do
      it 'returns a default response' do
        stub_request(:get, url).to_timeout

        response = subject.get_features_for_group(group)

        expect(response).to be {}
      end
    end
  end

  describe '#get_all' do
    let(:url) { "#{api_uri}/v2/all" }

    context 'all is ok' do
      it 'returns the bandiera response' do
        feature_hash = { 'pubserv' => { 'show-stuff' => true, 'show-other-stuff' => false } }
        stub         = stub_api_request(url, 'response' => feature_hash)
        response     = subject.get_all

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

          response = subject.get_all

          expect(response).to be {}
          expect(stub).to have_been_requested
        end
      end
    end

    context 'bandiera is down' do
      it 'returns a default response' do
        stub_request(:get, url).to_return(status: [0, ''])

        response = subject.get_all

        expect(response).to be {}
      end
    end

    context 'bandiera is having some problems' do
      it 'returns a default response' do
        stub_request(:get, url).to_return(status: 200, body: '<html></html>')

        response = subject.get_all

        expect(response).to be {}
      end
    end

    context 'bandiera times out' do
      it 'returns a default response' do
        stub_request(:get, url).to_timeout

        response = subject.get_all

        expect(response).to be {}
      end
    end
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
