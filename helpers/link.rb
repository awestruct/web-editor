require './jsonable'

module AwestructWebEditor
  # Public: Abstraction over HATEOS links.
  # Really not much more than a value object
  #
  # Examples
  #
  #   google_link = AwestructWebEditor::Link.new('The Google Search Engine', 'http://www.google.com')
  #   google_link.text
  #   # => 'The Google Search Engine'
  #
  #   google_link.to_json
  #   # => "{\"text\":\"The Google Search Engine\",\"url\":\"http://www.google.com\"}"
  class Link
    include AwestructWebEditor::JSONable
    attr_reader :text, :url

    # Public: Basic constructor.
    #
    # content - A hash of content for the link. Should contain 'text' and 'url'.
    def initialize(content = [])
      @text = content[:text] || content['text'] || ''
      @url = content[:url] || content['url'] || ''
    end
  end
end
