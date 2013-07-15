require 'find'
require 'pathname'
require 'shellwords'
require 'bundler'
require 'git'
require 'octokit'
require 'bundler'
require 'fileutils'

module AwestructWebEditor
  class Repository

    attr_reader :name, :uri
    attr_accessor :relative_path

    def initialize(content = [])
      @name = content['name'] || content[:name] || ''
      @uri = content['uri'] || content[:uri] || ''
      @relative_path = content['relative_path'] || content[:relative_path] || nil

      if ENV['OPENSHIFT_DATA_DIR']
        @base_repo_dir = File.join(ENV['OPENSHIFT_DATA_DIR'], 'repos')
      elsif ENV['RACK_ENV'] =~ /test/
        @base_repo_dir = 'tmp/repos'
      elsif content['base_repo_dir'] || content[:base_repo_dir]
        @base_repo_dir = content['base_repo_dir'] || content[:base_repo_dir]
      else
        @base_repo_dir = 'repos'
      end

      @git_repo = Git.open File.join @base_repo_dir, @name if (File.exists?(File.join @base_repo_dir, @name))
      @settings = File.open(File.join(@base_repo_dir, 'github-settings'), 'r') { |f| JSON.load(f) } if File.exists? File.join(@base_repo_dir, 'github-settings')
    end

    def clone
      Bundler.with_clean_env do
        Open3.popen3('bundle install', :chdir => File.absolute_path(base_repository_path)) do |stdin, stdout, stderr, wait_thr|
          exit_status = wait_thr.value.exitstatus
        end
      end

      github = Octokit::Client.new(:login => @settings['username'], :oauth_token => @settings['oauth_token'],
                                   :client_id => @settings['client_id'])
      fork_response = github.fork(URI(@settings['repo']).path[1..-1])

      FileUtils.mkdir_p(File.join @base_repo_dir, @name)
      Dir.chdir(File.join @base_repo_dir) do
        Git.clone(fork_response.ssh_url, @name)
      end

      @git_repo = Git.open File.join @base_repo_dir, @name
    end

    def all_files(ignores = [])
      default_ignores = [%r!(.gitignore$)|(.git$)|(_site$)|(.awestruct$)|(.awestruct_ignore$)|(_config$)|(_ext$)|(.git$)|(.travis.yml$)|(_tmp$)|(.sass-cache$)!]
      default_ignores << ignores.join unless ignores.empty?
      regexp_ignores = Regexp.union default_ignores
      files = []

      Find.find(base_repository_path) do |path|
        if regexp_ignores.match(path.to_s)
          Find.prune
        else
          unless File.basename(path.to_s) == @name
            files << file_info(path)

          end
        end
      end
      files
    end

    def base_repository_path
      File.join @base_repo_dir, @name
    end


    def save_file(name, content)
      if content.is_a? Hash
        IO.copy_stream(content[:tempfile], File.join(base_repository_path, name))
        content[:tempfile].unlink
        content[:tempfile].close
      else
        File.open(File.join(base_repository_path, name), 'w') do |f|
          f.write content
        end
      end
      @git_repo.add(Shellwords.escape name)
    end

    def remove_file(name)
      result = @git_repo.remove(Shellwords.escape name)
      path_to_file = File.join(base_repository_path, Shellwords.escape(name))
      File.delete(path_to_file) if File.exists? path_to_file
      !File.exists? path_to_file
    end

    def commit(message)
      @git_repo.commit_all(message)
      @git_repo.log(1).first # Give us back a commit object so we can actually query it
    end

    def fetch_remote(remote = 'upstream')
      @git_repo.fetch remote
    end

    def create_branch(branch_name, tracking_branch = 'upstream/master')
      fetch_remote tracking_branch.split('/').first
      system("git checkout -b #{branch_name} #{tracking_branch}")
    end

    def remove_branch(branch_name)
      @git_repo.branch('master').checkout
      @git_repo.branch(branch_name).delete
    end

    def branches
      @git_repo.branches
    end

    def push(remote = 'upstream')
      @git_repo.push(remote, 'HEAD')

    end

    def pull_request(title, body)
      github = Octokit::Client.new(:login => @settings['username'], :oauth_token => @settings['oauth_token'],
                                   :client_id => @settings['client_id'])
      github.create_pull_request("#{settings['username']}/#{@name}", 'master', @git_repo.lib.branch_current, title, body)
      @git_repo.branch('master').checkout
    end

    def file_content(file, binary = false)
      if binary
        File.open(File.join(base_repository_path, file), 'rb').read
      else
        File.open(File.join(base_repository_path, file), 'r').read
      end
    end

    def file_info(path)
      { :location => File.basename(path), :directory => File.directory?(path),
        :path_to_root => Pathname.new(path).relative_path_from(Pathname.new base_repository_path).dirname.to_s }
    end

    def log(count = 30)
      @git_repo.log count
    end
  end
end
