require 'multi_json'
require_relative 'spec_helper'

describe 'AwestructWebEditor::App' do
  context 'repo awestruct.org' do
    specify "retreiving files" do
      get '/repo/awestruct.org'
      expect(last_response.status).to eq 200

      json_response = MultiJson.load last_response.body
      expect(json_response["links"]).to have_at_least(100).items
      expect(json_response["links"][0]["text"]).to eql "news"
    end
  end
end
