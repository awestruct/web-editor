require 'pathname'
# TODO: require git

require './jsonable'

module AwestructWebEditor
  class Repository
    include AwestructWebEditor::JSONable

    BASE_REPO_DIR = 'repos'

    attr_reader :name, :uri
    attr_accessor :relative_path

    def initialization(content = [])
      @name = content['name'] || ''
      @uri = content['uri'] || ''
      @relative_path = content['relative_path'] || nil
    end

    def all_files()
      base_repository_path = File.join BASE_REPO_DIR, @name
      Pathname.glob(File.join(base_repository_path '**', '*')).collect do |f|
        # TODO include ignores
        f.relative_path_from(Pathname.new base_repository_path).to_s
      end
    end

    def save_file(name, content)

    end

    def commit(subject, body)

    end

  end
end
