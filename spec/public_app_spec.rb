require 'json'

require_relative 'spec_helper'

describe 'AwestructWebEditor::PublicApp' do
  specify 'when obtaining a list of repositories' do
    get '/repo'
    expect(last_response).to be_successful

    json_response = JSON.load last_response.body
    expect(json_response).to include('awestruct.org')
    expect(json_response['awestruct.org']).to have(1).items
    expect(json_response['awestruct.org']['links']).to have(1).items
    expect(json_response['awestruct.org']['links'][0]).to include 'text', 'url', 'method'
    expect(json_response['awestruct.org']['links'][0]['url']).to match(/\/repo\/awestruct\.org$/)
    expect(json_response['awestruct.org']['links'][0]['method']).to match(/GET/)
    expect(json_response['awestruct.org']['links'][0]['text']).to match(/awestruct\.org/)
  end

  context 'using repo awestruct.org' do
    let(:base_method) { '/repo/awestruct.org' }
    let(:repo) { AwestructWebEditor::Repository.new({ :name => 'awestruct.org' }) }

    specify 'when retrieving file list' do
      get "#{base_method}"
      expect(last_response).to be_successful

      json_response = JSON.load last_response.body
      expect(json_response).to have_at_least(5).items
      expect(json_response['news']['children']).to have_at_least(3).items # one may be deleted depending on order of test execution
                                                                          # FIXME: eventually we need to check .awestruct_ignore and not do a rendered link for things awestruct ignores
      expect(json_response['news']['children']['awestruct-0-5-0-released.adoc']['links'][0]['url']).to eq('http://example.org/repo/awestruct.org/news/awestruct-0-5-0-released.adoc')
      expect(json_response['news']['children']['awestruct-0-5-1-released.adoc']['links'][0]['url']).to eq('http://example.org/repo/awestruct.org/news/awestruct-0-5-1-released.adoc')
      expect(json_response['news']['children']['awestruct-0-5-2-released.adoc']['links'][0]['url']).to eq('http://example.org/repo/awestruct.org/news/awestruct-0-5-2-released.adoc')
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
        expect(json_return['content']).to be_a String
        expect(json_return['content']).to match /\n/
        expect(json_return['content'].length).to be > 0
        expect(json_return['links']).to have(5).items
      end
    end

    context 'when modifying a file' do
      let(:filename) { 'extensions.md' }

      around(:each) do |example|
        original_content = repo.file_content filename

        example.metadata[:original_content] = original_content
        example.run
        repo.save_file filename, original_content
      end

      let(:changed_content) { @example.metadata[:original_content].gsub /Extensions/, 'Plugins' }

      specify do
        post "#{base_method}/#{filename}", 'content' => changed_content
        expect(last_response).to be_successful
        expect(repo.file_content filename).to_not eql @example.metadata[:original_content]
        expect(repo.file_content filename).to eql changed_content
      end
    end

    context 'when saving a new file' do
      context 'using an image' do
        let(:filename) { 'sample image.png' }

        around(:each) do |example|
          dest = File.open('tmp/sample_image.png', 'wb')
          source = File.open 'tmp/repos/awestruct.org/images/pagination_template.png', 'rb'
          FileUtils.copy_stream source, dest
          dest.close
          source.close
          example.run
          FileUtils.rm "tmp/repos/awestruct.org/images/#{filename}" if File.exists?("tmp/repos/awestruct.org/images/#{filename}")
        end

        specify do
          put "#{base_method}/images/#{URI.escape filename}",
              :content => Rack::Test::UploadedFile.new('tmp/sample_image.png', 'image/png', true)
          expect(last_response).to be_successful
          expect(repo.file_content(File.join('images', filename), true)).to_not be_nil
        end
      end
    end

    context 'when deleting a file' do
      let(:filename) { 'helpers/partial.md' }
      specify do
        delete "#{base_method}/#{filename}"
        expect(last_response).to be_successful
        expect(repo.all_files).to_not include ({ :location => File.basename(filename), :directory => false,
                                                 :path_to_root => 'helpers' })
      end
    end

  end
end
