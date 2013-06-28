require 'pathname'
require 'git'
require 'octokit'

require_relative 'jsonable'

module AwestructWebEditor
  class Repository
    include AwestructWebEditor::JSONable

    attr_reader :name, :uri
    attr_accessor :relative_path

    def initialize(content = [])
      @name = content['name'] || ''
      @uri = content['uri'] || ''
      @relative_path = content['relative_path'] || nil
      @base_repo_dir = content['base_repo_dir'] || ENV['RACK_ENV'] == 'test' ? 'tmp' : 'repos'
    end

    def all_files(ignores = [])
      base_repository_path = File.join @base_repo_dir, @name
      default_ignores = %w(.gitignore .git _site .awestruct .awestruct_ignore _config _ext .git)
      default_ignores << ignores.join unless ignores.empty?
      regexp_ignores = Regexp.union default_ignores
      files = Pathname.glob(File.join(base_repository_path, '**', '*'))
      files.map! { |f| f.relative_path_from(Pathname.new base_repository_path).to_s}
      files.reject { |f| regexp_ignores.match(f) }
    end

    def save_file(name, content)

    end

    def commit(subject, body)

    end

  end
end
