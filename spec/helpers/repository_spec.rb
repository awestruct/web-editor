require 'spec_helper'

RSpec::Matchers.define :a_link do |expected|
  match do |actual|
    actual.is_a?(Hash) && ((actual[:location] == expected[:location]) && (actual[:directory] == expected[:directory]))
  end
  description do
    "a link '#{expected}'"
  end
end

describe 'AwestructWebEditor::Repository' do
  context '#all_files' do
    subject { AwestructWebEditor::Repository.new({ 'name' => 'awestruct.org', 'relative_path' => 'awestruct.org',
                                                   'base_repo_dir' => 'tmp/repos' }).all_files }

    it { should include a_link({ :location => 'news', :directory => true }) }
    it { should include a_link({ :location => 'Gemfile', :directory => false }) }
    it { should_not include a_link({ :location => '_site/news/index.html', :directory => false }) }
    it { should_not include a_link({ :location => '_ext/', :directory => true }) }
    it { should have_at_least(100).items }
  end

  context "#remove_file('helpers/partial.md')" do
    let(:repo) { AwestructWebEditor::Repository.new({ 'name' => 'awestruct.org', 'relative_path' => 'awestruct.org',
                                                      'base_repo_dir' => 'tmp/repos' }) }
    let(:response) { repo.remove_file('news/awestruct-0-5-1-released.adoc') }

    specify 'should succeed' do
      expect(response).to be_true
    end

  end

  context "#commit('New file added')" do
    # setup for a commit, as we can't guarantee order
    let(:repo) { AwestructWebEditor::Repository.new({ 'name' => 'awestruct.org', 'relative_path' => 'awestruct.org',
                                                      'base_repo_dir' => 'tmp/repos' }) }
    before(:each) do
      repo.save_file('new_file.txt', 'Hello World!!')
    end

    let(:result) { AwestructWebEditor::Repository.new({ 'name' => 'awestruct.org', 'relative_path' => 'awestruct.org',
                                                        'base_repo_dir' => 'tmp/repos' }).commit('New File added') }

    specify 'returns a commit object' do
      expect(result).to be_a(Git::Object::Commit)
      expect(result.message).to match(/New File added/)
    end
  end

end