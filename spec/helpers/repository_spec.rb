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
  context 'all files' do
    subject { AwestructWebEditor::Repository.new({'name' => 'awestruct.org', 'relative_path' => 'awestruct.org', 'base_repo_dir' => 'tmp'}).all_files }

    it { should include a_link({:location => 'news', :directory => true}) }
    it { should include a_link({:location => 'Gemfile', :directory => false}) }
    it { should_not include a_link({:location => '_site/news/index.html', :directory => false}) }
    it { should_not include a_link({:location => '_ext/', :directory => true}) }
    it { should have_at_least(100).items }
  end

end