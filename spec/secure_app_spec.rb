require 'json'

require_relative 'spec_helper'

describe 'AwestructWebEditor::SecureApp' do
  context 'when requesting http://example.org/settings' do
    specify 'redirects' do
      get '/settings'

      expect(last_response.status).to be_eql 301
    end
  end
  context 'when requesting https://example.org/settings' do
    specify do
      get 'https://example.org/settings'

      expect(last_response).to be_successful
      expect(last_response.body).to_not be_empty
      json_response = JSON.load last_response.body
      expect(json_response['username']).to eql('LightGuard')
    end
  end
end

