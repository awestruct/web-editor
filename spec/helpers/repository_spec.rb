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
  context 'while using awestruct.org' do
    let(:repo) { AwestructWebEditor::Repository.new({ 'name' => 'awestruct.org', 'relative_path' => 'awestruct.org',
                                                      'base_repo_dir' => 'tmp/repos' }) }
    context '#all_files' do
      subject { repo.all_files }

      it { should include a_link({ :location => 'news', :directory => true }) }
      it { should include a_link({ :location => 'Gemfile', :directory => false }) }
      it { should_not include a_link({ :location => '_site/news/index.html', :directory => false }) }
      it { should_not include a_link({ :location => '_ext/', :directory => true }) }
      it { should have_at_least(100).items }
    end

    context "#remove_file('helpers/partial.md')" do
      let(:response) { repo.remove_file('news/awestruct-0-5-1-released.adoc') }

      specify 'should succeed' do
        expect(response).to be_true
      end

    end

    context "#commit('New file added')" do
      # setup for a commit, as we can't guarantee order
      before(:each) do
        repo.save_file('new_file.txt', 'Hello World!!')
      end

      let(:result) { repo.commit('New File added') }

      specify 'returns a commit object' do
        expect(result).to be_a(Git::Object::Commit)
        expect(result.message).to match(/New File added/)
      end
    end

    context "#create_branch('new_branch', 'origin/master')" do
      after(:each) do
        repo.remove_branch 'new_branch'
      end
      subject { repo.create_branch('new_branch', 'origin/master') }

      specify 'should create a new branch named "new_branch"' do
        expect(subject).to be_true
        expect(repo.branches['new_branch']).to_not be_nil
      end

    end
  end
end