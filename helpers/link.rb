require 'json'

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
    attr_reader :text, :url, :method

    # Public: Basic constructor.
    #
    # content - A hash of content for the link. Should contain 'text' and 'url'.
    def initialize(content = {})
      @text = content[:text] || content['text'] || content['url'] || ''
      @url = content[:url] || content['url'] || ''
      @method = content[:method] || content['method'] || 'GET'
    end

    def to_json(obj = nil)
      return "{\"text\":\"#{@text}\",\"url\":\"#{@url}\",\"method\":\"#{@method}\"}"
    end

    def self.from_json!(json_string)
      obj = JSON.load json_string

      Link.new({:text => obj['text'], :url => obj['url'], :method => obj['method']})
    end

    def to_hash
      {:text => @text, :url => @url, :method => @method}
    end

    def eql?(other)
      if other.equal?(self)
        return true
      elsif !self.class.equal?(other.class)
        return false
      end

      return other.text == @text && other.url == @url && other.method == @method
    end


  end
end
