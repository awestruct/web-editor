require 'spec_helper'

describe AwestructWebEditor::Link do

  context 'loading from JSON' do
    subject { AwestructWebEditor::Link.from_json! "{\"text\":\"Hello\",\"url\":\"http://www.example.com\"}" }

    it { should eql AwestructWebEditor::Link.new :text => "Hello", :url => "http://www.example.com" }
  end

  context 'saving to JSON' do
    subject { AwestructWebEditor::Link.new(:text => "Hello", :url => "http://www.example.com").to_json }

    it { should eql "{\"text\":\"Hello\",\"url\":\"http://www.example.com\"}" }
  end
end