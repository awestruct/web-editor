require 'spec_helper'

describe 'AwestructWebEditor::Repository' do
  context 'all files' do
    subject { AwestructWebEditor::Repository.new({'name' => 'awestruct.org', 'relative_path' => 'awestruct.org', 'base_repo_dir' => 'tmp'}).all_files }

    it { should include 'Rakefile', 'Gemfile' }
    it { should_not include '_site/news/index.html' }
    it { should_not include '_ext/yard.rb' }
    it { should have_at_least(100).items }
  end

end