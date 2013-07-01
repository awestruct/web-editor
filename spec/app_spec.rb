require 'json'

require_relative 'spec_helper'

describe 'AwestructWebEditor::App' do
  context 'using repo awestruct.org' do
    let(:base_method) { '/repo/awestruct.org' }
    specify 'when retrieving file list' do
      get "#{base_method}"
      expect(last_response).to be_successful

      json_response = JSON.load last_response.body
      expect(json_response).to have_at_least(24).items
      expect(json_response['news']['children']).to have_at_least(10).items
      # FIXME: eventually we need to check .awestruct_ignore and not do a rendered link for things awestruct ignores
      expect(json_response['Gemfile']['links']).to have_exactly(5).items
      expect(json_response['Gemfile']['links'][0]).to include 'text', 'url', 'method'
      expect(json_response['extensions']['children']['atomizer']['children']['description.md']['links'][0]['url']).to eq('http://example.org/repo/awestruct.org/extensions/atomizer/description.md')
    end

    context 'when retrieving file content' do
      specify 'with deeply nested' do
        get "#{base_method}/extensions/atomizer/description.md"
        expect(last_response).to be_successful
        expect(last_response.content_length).to be > 0
        json_return = JSON.load(last_response.body)
        expect(json_return['content'].length).to be > 0
        expect(json_return['links']).to have(5).items
      end

      specify 'with no nesting' do
        get "#{base_method}/gallery.html.haml"
        expect(last_response).to be_successful
        expect(last_response.content_length).to be > 0
        json_return = JSON.load(last_response.body)
        expect(json_return['content'].length).to be > 0
        expect(json_return['links']).to have(5).items
      end
    end
  end
end
