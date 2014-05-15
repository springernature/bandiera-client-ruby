require 'spec_helper'

describe Bandiera::Client do
  let(:base_uri)  { 'http://bandiera.com' }
  let(:api_uri)   { "#{base_uri}/api" }
  let(:logger)    { double(debug: nil) }
  subject         { Bandiera::Client.new(api_uri, logger) }

  context 'when a client name is provided' do
    let(:group)   { 'pubserv' }
    let(:feature) { 'log-stats' }
    let(:url)     { "#{api_uri}/v2/groups/#{group}/features/#{feature}" }

    it 'sends it as part of the headers' do
      stub = stub_api_request(url, { 'response' => true }, { 'Bandiera-Client' => 'asdf' })
      client = Bandiera::Client.new api_uri, logger, 'asdf'
      client.enabled? group, feature
      expect(stub).to have_been_requested
    end
  end

  describe '#enabled?' do
    let(:group)   { 'pubserv' }
    let(:feature) { 'log-stats' }
    let(:url)     { "#{api_uri}/v2/groups/#{group}/features/#{feature}" }

    context 'all is ok' do
      context 'and the group/feature exists' do
        it 'returns the feature' do
          stub     = stub_api_request(url, 'response' => true)
          response = subject.enabled?(group, feature)

          expect(response).to be_true
          expect(stub).to have_been_requested
        end

        context 'and the user has passed through a user_group param' do
          it 'then this is passed through to the API' do
            stub = stub_request(:get, url)
                     .with(query: { user_group: 'admin' })
                     .to_return(
                       body: JSON.generate('response' => true),
                       headers: { 'Content-Type' => 'application/json' }
                     )

            subject.enabled?(group, feature, user_group: 'admin')

            expect(stub).to have_been_requested
          end
        end
      end

      context "but the group doesn't exist" do
        it 'returns a false, and logs a warning' do
          stub = stub_api_request(url, 'response' => false, 'warning' => 'The group does not exist')

          logger.should_receive(:warn).once

          response = subject.enabled?(group, feature)

          expect(response).to be_false
          expect(stub).to have_been_requested
        end
      end

      context "and the group exists, but the feature doesn't" do
        it 'returns a false, and logs a warning' do
          stub = stub_api_request(url, 'response' => false, 'warning' => 'The feature does not exist')

          logger.should_receive(:warn).once

          response = subject.enabled?(group, feature)

          expect(response).to be_false
          expect(stub).to have_been_requested
        end
      end
    end

    context 'bandiera is down' do
      it 'returns false, and logs a warning' do
        stub_request(:get, url).to_return(status: [0, ''])

        logger.should_receive(:warn).once

        response = subject.enabled?(group, feature)

        expect(response).to be_false
      end
    end

    context 'bandiera is having some problems' do
      it 'returns false, and logs a warning' do
        stub_request(:get, url).to_return(status: 500, body: '')

        logger.should_receive(:warn).once

        response = subject.enabled?(group, feature)

        expect(response).to be_false
      end
    end

    context 'bandiera times out' do
      it 'returns false, and logs a warning' do
        stub_request(:get, url).to_timeout

        logger.should_receive(:warn).once

        response = subject.enabled?(group, feature)

        expect(response).to be_false
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
