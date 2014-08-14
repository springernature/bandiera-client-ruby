require 'spec_helper'

describe Bandiera::Client do
  let(:base_uri)  { 'http://bandiera.com' }
  let(:api_uri)   { "#{base_uri}/api" }
  let(:logger)    { double.as_null_object }
  subject         { Bandiera::Client.new(api_uri, logger) }

  context 'when a client name is provided' do
    let(:group)   { 'pubserv' }
    let(:feature) { 'log-stats' }
    let(:url)     { "#{api_uri}/v2/groups/#{group}/features" }

    it 'sends it as part of the headers' do
      stub = stub_api_request(url, { 'response' => {} }, { 'Bandiera-Client' => 'asdf' })
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

  describe '#enabled?' do
    context 'with cache strategy :single_feature' do
      before do
        subject.cache_strategy = :single_feature
      end

      context 'and an empty cache' do
        it 'calls #get_feature' do
          expect(subject).to receive(:get_feature).once
          subject.enabled?('foo', 'bar')
        end
      end

      context 'and a primed cache' do
        before do
          cache_key = subject.send(:build_cache_key, 'foo', 'bar', {})
          subject.cache.store(cache_key, false)
        end

        it 'does not call #get_feature' do
          expect(subject).to_not receive(:get_feature)
          subject.enabled?('foo', 'bar')
        end
      end
    end

    context 'with cache strategy :group' do
      before do
        subject.cache_strategy = :group
      end

      context 'and an empty cache' do
        it 'calls #get_features_for_group' do
          expect(subject).to receive(:get_features_for_group).once
          subject.enabled?('foo', 'bar')
        end
      end

      context 'and a primed cache' do
        before do
          cache_key = subject.send(:build_cache_key, 'foo', 'bar', {})
          subject.cache.store(cache_key, false)
        end

        it 'does not call #get_features_for_group' do
          expect(subject).to_not receive(:get_features_for_group)
          subject.enabled?('foo', 'bar')
        end
      end
    end

    context 'with cache strategy :all' do
      before do
        subject.cache_strategy = :all
      end

      context 'and an empty cache' do
        it 'calls #get_all' do
          expect(subject).to receive(:get_all).once
          subject.enabled?('foo', 'bar')
        end
      end

      context 'and a primed cache' do
        before do
          cache_key = subject.send(:build_cache_key, 'foo', 'bar', {})
          subject.cache.store(cache_key, false)
        end

        it 'does not call #get_all' do
          expect(subject).to_not receive(:get_all)
          subject.enabled?('foo', 'bar')
        end
      end
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

      it 'stores the feature value in the cache' do
        stub_api_request(url, 'response' => true)
        cache_key = subject.send(:build_cache_key, group, feature, {})

        subject.get_feature(group, feature)
        expect(subject.cache.key?(cache_key)).to be true
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

          expect(logger).to receive(:warn).once

          response = subject.get_feature(group, feature)

          expect(response).to be false
          expect(stub).to have_been_requested
        end
      end
    end

    context 'bandiera is down' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_return(status: [0, ''])

        expect(logger).to receive(:warn).once

        response = subject.get_feature(group, feature)

        expect(response).to be false
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_return(status: [0, ''])

        expect(subject.cache).to_not receive(:store)

        subject.get_feature(group, feature)
      end
    end

    context 'bandiera is having some problems' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_return(status: 500, body: '')

        expect(logger).to receive(:warn).once

        response = subject.get_feature(group, feature)

        expect(response).to be false
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_return(status: 500, body: '')

        expect(subject.cache).to_not receive(:store)

        subject.get_feature(group, feature)
      end
    end

    context 'bandiera times out' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_timeout

        expect(logger).to receive(:warn).once

        response = subject.get_feature(group, feature)

        expect(response).to be false
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_timeout

        expect(subject.cache).to_not receive(:store)

        subject.get_feature(group, feature)
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

      it 'stores the feature values in the cache' do
        feature_hash = { 'show-stuff' => true, 'show-other-stuff' => false }
        stub_api_request(url, 'response' => feature_hash)

        subject.get_features_for_group(group)

        cache_key = subject.send(:build_cache_key, group, 'show-stuff', {})
        expect(subject.cache.key?(cache_key)).to be true

        cache_key = subject.send(:build_cache_key, group, 'show-other-stuff', {})
        expect(subject.cache.key?(cache_key)).to be true
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

          expect(logger).to receive(:warn).once

          response = subject.get_features_for_group(group)

          expect(response).to be {}
          expect(stub).to have_been_requested
        end
      end
    end

    context 'bandiera is down' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_return(status: [0, ''])

        expect(logger).to receive(:warn).once

        response = subject.get_features_for_group(group)

        expect(response).to be {}
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_return(status: [0, ''])

        expect(subject.cache).to_not receive(:store)

        subject.get_features_for_group(group)
      end
    end

    context 'bandiera is having some problems' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_return(status: 500, body: '')

        expect(logger).to receive(:warn).once

        response = subject.get_features_for_group(group)

        expect(response).to be {}
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_return(status: 500, body: '')

        expect(subject.cache).to_not receive(:store)

        subject.get_features_for_group(group)
      end
    end

    context 'bandiera times out' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_timeout

        expect(logger).to receive(:warn).once

        response = subject.get_features_for_group(group)

        expect(response).to be {}
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_timeout

        expect(subject.cache).to_not receive(:store)

        subject.get_features_for_group(group)
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

      it 'stores the feature values in the cache' do
        feature_hash = { 'pubserv' => { 'show-stuff' => true, 'show-other-stuff' => false } }
        stub_api_request(url, 'response' => feature_hash)

        subject.get_all

        cache_key = subject.send(:build_cache_key, 'pubserv', 'show-stuff', {})
        expect(subject.cache.key?(cache_key)).to be true

        cache_key = subject.send(:build_cache_key, 'pubserv', 'show-other-stuff', {})
        expect(subject.cache.key?(cache_key)).to be true
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

          expect(logger).to receive(:warn).once

          response = subject.get_all

          expect(response).to be {}
          expect(stub).to have_been_requested
        end
      end
    end

    context 'bandiera is down' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_return(status: [0, ''])

        expect(logger).to receive(:warn).once

        response = subject.get_all

        expect(response).to be {}
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_return(status: [0, ''])

        expect(subject.cache).to_not receive(:store)

        subject.get_all
      end
    end

    context 'bandiera is having some problems' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_return(status: 500, body: '')

        expect(logger).to receive(:warn).once

        response = subject.get_all

        expect(response).to be {}
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_return(status: 500, body: '')

        expect(subject.cache).to_not receive(:store)

        subject.get_all
      end
    end

    context 'bandiera times out' do
      it 'returns a default response and logs a warning' do
        stub_request(:get, url).to_timeout

        expect(logger).to receive(:warn).once

        response = subject.get_all

        expect(response).to be {}
      end

      it 'does not store anything in the cache' do
        stub_request(:get, url).to_timeout

        expect(subject.cache).to_not receive(:store)

        subject.get_all
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
