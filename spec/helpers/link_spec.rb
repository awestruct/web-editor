require 'spec_helper'

describe AwestructWebEditor::Link do

  context 'when loading from JSON' do
    subject { AwestructWebEditor::Link.from_json! "{\"text\":\"Hello\",\"url\":\"http://www.example.com\"}" }

    it { should eql AwestructWebEditor::Link.new :text => "Hello", :url => "http://www.example.com" }

    context 'when using different HTTP methods' do
      subject { AwestructWebEditor::Link.from_json! "{\"text\":\"Hello\",\"url\":\"http://www.example.com\",\"method\":\"POST\"}" }

      it { should eql AwestructWebEditor::Link.new :text => "Hello", :url => "http://www.example.com", :method => "POST" }
    end
  end

  context 'when saving to JSON' do
    subject { AwestructWebEditor::Link.new(:text => "Hello", :url => "http://www.example.com").to_json }

    it { should eql "{\"text\":\"Hello\",\"url\":\"http://www.example.com\",\"method\":\"GET\"}" }
  end

end