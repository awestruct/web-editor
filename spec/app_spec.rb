require 'multi_json'
require_relative 'spec_helper'

describe 'AwestructWebEditor::App' do
  context 'repo awestruct.org' do
    specify "retreiving files" do
      get '/repo/awestruct.org'
      expect(last_response.status).to eq 200

      json_response = MultiJson.load last_response.body
      expect(json_response).to have_at_least(24).items
      expect(json_response['news']['children']).to have_at_least(10).items
      expect(json_response['Gemfile']['links']).to have_exactly(4).items
      expect(json_response['Gemfile']['links'][0]).to include 'text', 'url', 'method'
      expect(json_response['extensions']['children']['atomizer']['children']['description.md']['links'][0]['url']).to eq('http://example.org/repo/awestruct.org/extensions/atomizer/description.md')
    end
  end
end
