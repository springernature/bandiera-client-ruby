require 'spec_helper'
require 'macmillan/utils/rspec/rack_test_helper'

describe Bandiera::Middleware do
  let(:app)             { ->(env) { [200, env, 'app'] } }
  let(:request)         { req_for('http://example.com') }
  let(:bandiera_client) { double(:bandiera_client) }
  let(:bandiera_groups) { [] }
  let(:user)            { double(:user, email: 'bob.flemming@cough.com') }
  let(:user_uuid)       { '12345-12345-12345' }

  subject { described_class.new(app, client: bandiera_client, groups: bandiera_groups) }

  context 'when a bandiera client has NOT been passed' do
    it 'raises an error' do
      expect { described_class.new(app) }.to raise_error(ArgumentError)
    end
  end

  context 'feature flag "groups"' do
    context 'when NO feature flag "groups" have been defined' do
      it 'calls #get_all on the bandiera_client' do
        expect(bandiera_client).to receive(:get_all).and_return({})

        subject.call(request.env)
      end

      it 'stores the returned flags in the env' do
        pubserv_flags     = { 'show-stuff' => true }
        search_flags      = { 'show-search' => false }
        bandiera_response = { 'pubserv' => pubserv_flags, 'search' => search_flags }

        expect(bandiera_client).to receive(:get_all).and_return(bandiera_response)

        _status, headers, _body = subject.call(request.env)

        expect(headers['bandiera.pubserv']).to eq(pubserv_flags)
        expect(headers['bandiera.search']).to eq(search_flags)
      end
    end

    context 'when SOME feature flag "groups" have been defined' do
      let(:bandiera_groups) { ['search'] }

      it 'calls #get_features_for_group on the bandiera_client' do
        expect(bandiera_client).to receive(:get_features_for_group).and_return([])

        subject.call(request.env)
      end

      it 'stores the returned flags in the env' do
        bandiera_response = { 'show-search' => false }

        expect(bandiera_client).to receive(:get_features_for_group).and_return(bandiera_response)

        _status, headers, _body = subject.call(request.env)

        expect(headers['bandiera.search']).to eq(bandiera_response)
      end
    end
  end

  context '"uuid_env_key"' do
    before do
      request.env[Macmillan::Utils::Middleware::Uuid.env_key] = user_uuid
    end

    context 'HAS NOT been set' do
      it 'uses the default key from Macmillan::Utils' do
        expect(bandiera_client).to receive(:get_all).with(hash_including(user_id: user_uuid)).and_return({})

        subject.call(request.env)
      end

      context "and the nothing has set the #{Macmillan::Utils::Middleware::Uuid.env_key} value" do
        it 'passes nil to the #user_id param' do
          request.env.delete(Macmillan::Utils::Middleware::Uuid.env_key)

          expect(bandiera_client).to receive(:get_all).with(hash_including(user_id: nil)).and_return({})

          subject.call(request.env)
        end
      end
    end

    context 'HAS been set' do
      let(:uuid_env_key) { 'wibble' }
      let(:uuid)         { 'qwerty' }

      subject { described_class.new(app, client: bandiera_client, groups: bandiera_groups, uuid_env_key: uuid_env_key) }

      it 'uses the key passed into it' do
        request.env[uuid_env_key] = uuid

        expect(bandiera_client).to receive(:get_all).with(hash_including(user_id: uuid)).and_return({})

        subject.call(request.env)
      end
    end
  end

  context '"user_env_key"' do
    before do
      request.env['current_user'] = user
    end

    context 'when there is no current user' do
      it 'does not cause errors' do
        expect do
          request.env['current_user'] = nil

          expect(bandiera_client).to receive(:get_all).with(hash_including(user_group: nil)).and_return({})

          subject.call(request.env)
        end.to_not raise_error
      end
    end

    context 'HAS NOT been set' do
      it 'uses the default key - "current_user"' do
        expect(bandiera_client).to receive(:get_all).with(hash_including(user_group: user.email)).and_return({})

        subject.call(request.env)
      end
    end

    context 'HAS been set' do
      let(:user_env_key) { 'wibble' }
      let(:user)         { double(:user, email: 'robert.paulson@example.com') }

      subject { described_class.new(app, client: bandiera_client, groups: bandiera_groups, user_env_key: user_env_key) }

      it 'uses the key passed to it' do
        request.env[user_env_key] = user

        expect(bandiera_client).to receive(:get_all).with(hash_including(user_group: user.email)).and_return({})

        subject.call(request.env)
      end
    end
  end

  context '"user_group_method"' do
    before do
      request.env['current_user'] = user
    end

    context 'when there is no current user' do
      it 'does not cause errors' do
        expect do
          request.env['current_user'] = nil

          expect(bandiera_client).to receive(:get_all).with(hash_including(user_group: nil)).and_return({})

          subject.call(request.env)
        end.to_not raise_error
      end
    end

    context 'HAS NOT been set' do
      it 'uses the default method - "email"' do
        email = 'ron.manager@football.com'

        expect(user).to receive(:public_send).with(:email).once.and_return(email)
        expect(bandiera_client).to receive(:get_all).with(hash_including(user_group: email)).and_return({})

        subject.call(request.env)
      end
    end

    context 'HAS been set' do
      subject { described_class.new(app, client: bandiera_client, groups: bandiera_groups, user_group_method: :role) }

      it 'uses the method passed to it' do
        role = 'Administrator'

        expect(user).to receive(:public_send).with(:role).once.and_return(role)
        expect(bandiera_client).to receive(:get_all).with(hash_including(user_group: role)).and_return({})

        subject.call(request.env)
      end
    end
  end
end
