require 'multi_json'
require_relative 'spec_helper'

describe 'AwestructWebEditor::App' do
  context 'repo awestruct.org' do
    let(:base_method) {'/repo/awestruct.org'}
    specify 'retrieving file list' do
      get "#{base_method}"
      expect(last_response.status).to eq 200

      json_response = MultiJson.load last_response.body
      expect(json_response).to have_at_least(24).items
      expect(json_response['news']['children']).to have_at_least(10).items
      expect(json_response['Gemfile']['links']).to have_exactly(4).items
      expect(json_response['Gemfile']['links'][0]).to include 'text', 'url', 'method'
      expect(json_response['extensions']['children']['atomizer']['children']['description.md']['links'][0]['url']).to eq('http://example.org/repo/awestruct.org/extensions/atomizer/description.md')
    end

    specify 'retrieving file content' do
      get "#{base_method}/extensions/atomizer/description.md"
      expect(last_response.status).to eq 200
      expect(last_response.header['Content-Type']).to eq 'text/plain;charset=utf-8'
    end
  end
end
