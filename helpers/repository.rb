require 'find'
require 'pathname'
require 'shellwords'
require 'bundler'
require 'git'
require 'octokit'
require 'bundler'
require 'fileutils'
require 'logger'

module AwestructWebEditor
  class Repository

    attr_reader :name, :uri
    attr_accessor :relative_path

    def initialize(content = [])
      @name = content['name'] || content[:name] || ''
      @uri = content['uri'] || content[:uri] || ''
      @relative_path = content['relative_path'] || content[:relative_path] || nil

      log_file = File.new(File.join((ENV['OPENSHIFT_RUBY_LOG_DIR'] || 'log'), 'application.log' ), 'a+')
      log_file.sync = true
      @logger = Logger.new(log_file, 'daily')

      if ENV['OPENSHIFT_DATA_DIR']
        @base_repo_dir = File.join(ENV['OPENSHIFT_DATA_DIR'], 'repos', content[:username])
        FileUtils.mkdir(File.join @base_repo_dir) unless File.exists? @base_repo_dir
      elsif ENV['RACK_ENV'] =~ /test/
        @base_repo_dir = "tmp/repos/#{content[:username]}"
      elsif content['base_repo_dir'] || content[:base_repo_dir]
        @base_repo_dir = content['base_repo_dir'] || content[:base_repo_dir]
      else
        @base_repo_dir = "repos/#{content[:username]}"
      end

      @git_repo = Git.open File.join @base_repo_dir, @name if (File.exists?(File.join @base_repo_dir, @name))
      @settings = File.open(File.join(@base_repo_dir, 'github-settings'), 'r') { |f| JSON.load(f) } if File.exists? File.join(@base_repo_dir, 'github-settings') || {}
      @settings['oauth_token'] = content['token'] || content[:token] || nil
      create_github_client.user
    end

    def init_empty
      Dir.chdir(File.join @base_repo_dir) do |_|
        @git_repo = Git.init(@name)
      end
    end

    def add_creds
      doc = <<CONFIG
[core]
	repositoryformatversion = 0
	filemode = true
	bare = false
	logallrefupdates = true
[credential "https://github.com"]
	username = #{@settings['oauth_token']}
	helper = "!f() { echo 'password=x-oauth-basic'; }; f"
CONFIG

      Dir.chdir(File.join @base_repo_dir, @name, '.git') do
        File.open('config', 'w') { |f| f.write(doc) }
      end
    end

    def clone_repo
      github = create_github_client
      begin
        @logger.info 'creating github fork'
        fork_response = github.fork(URI(@settings['repo']).path[1..-1])
      rescue Exception => e
        return [500, e.message]
      end

      Dir.chdir(File.join @base_repo_dir) do
        git = Git.open(@name)
        @logger.debug "Cloning fork - #{fork_response.clone_url}"
        git.add_remote('origin', fork_response.clone_url)
        @logger.debug "Adding upstream fork - #{fork_response.parent.git_url}"
        git.add_remote('upstream', fork_response.parent.clone_url)

        @logger.debug 'pulling from git'
        Open3.popen3("git pull upstream master") do |_, _, stderr, wait_thr|
          exit_value = wait_thr.value
          @logger.debug "pull exit status: #{exit_value}"
          error = stderr.readlines.join "\n"
          @logger.debug "pulling error: #{error}" unless error.empty?
        end
      end

      @git_repo = Git.open File.join @base_repo_dir, @name

      @logger.debug 'Starting bundle install'
      Bundler.with_clean_env do
        Open3.popen3('bundle install', :chdir => File.absolute_path(base_repository_path)) do |_, _, stderr, wait_thr|
          exit_status = wait_thr.value.exitstatus
          [exit_status, stderr.readlines().join("\n")]
        end
      end
    end

    def all_files(allows = [], dir = '')
      @logger.info "Finding all files, additional allows #{allows}"
      default_allows = [%r!(.ad)|(.adoc)|(.adoc)|(.jpg)|(.jpeg)|(.png)|(.gif)!]
      default_allows << allows.join unless allows.empty?
      regexp_ignores = Regexp.union default_allows

      default_ignores = [%r!(.gitignore$)|(.git$)|(_site$)|(.awestruct$)|(.awestruct_ignore$)|(_config$)|(_ext$)|(.git$)|(.travis.yml$)|(_tmp$)|(.sass-cache$)!]
      files = []

      if File.exists?(File.join(base_repository_path, dir))
        Find.find(File.join(base_repository_path, dir)) do |path|
          if Regexp.union(default_ignores).match(path.to_s)
            Find.prune
          end

          if regexp_ignores.match(path.to_s) || File.directory?(path)
            if File.basename(path.to_s) != @name
              files << file_info(path, dir)
            end
          end
        end
      end

      files
    end

    def base_repository_path
      File.join @base_repo_dir, @name
    end


    def save_file(name, content)
      @logger.info "Saving file #{name}"
      if content.is_a? Hash
        @logger.debug 'Saving new file'
        IO.copy_stream(content[:tempfile], File.join(base_repository_path, name))
        content[:tempfile].unlink
        content[:tempfile].close
      else
        File.open(File.join(base_repository_path, name), 'w') do |f|
          f.write content
        end
      end
      @logger.debug 'Adding file to git'
      @git_repo.add(Shellwords.escape name)
    end

    def remove_file(name)
      @logger.info "Removing file #{name}"
      @git_repo.remove(Shellwords.escape name)
      path_to_file = File.join(base_repository_path, Shellwords.escape(name))
      File.delete(path_to_file) if File.exists? path_to_file
      !File.exists? path_to_file
    end

    def commit(message)
      @logger.info "Commiting with message #{message}"
      current_user = create_github_client.user
      @git_repo.commit_all(message, :author => "current_user['name'] <#{current_user['email']}>")
      @git_repo.log(1).first # Give us back a commit object so we can actually query it
    end

    def fetch_remote(remote = 'upstream')
      @logger.info "Fetching remote #{remote}"
      Open3.popen3("git fetch #{remote}",
                   :chdir => File.absolute_path(base_repository_path)) do |_, _, stderr, wait_thr|
        exit_value = wait_thr.value
        @logger.debug "fetch exit status: #{exit_value}"
        error = stderr.readlines.join "\n"
        @logger.debug "fetch error: #{error}" unless error.empty?
      end
    end

    def create_branch(branch_name)
      upstream_repo = create_github_client.repository(Octokit::Repository.from_url @settings['repo'])
      fetch_remote
      @logger.info "creating branch #{branch_name} based on 'upstream/#{upstream_repo.master_branch}'"
      system("git checkout -b #{branch_name} upstream/#{upstream_repo.master_branch}")
    end

    def switch_branch(branch_name)
      @git_repo.checkout branch_name, {:force => true}
      [200, '']
    end

    def rebase(overwrite, remote = 'upstream')
      fetch_remote remote
      upstream_repo = create_github_client.repository(Octokit::Repository.from_url @settings['repo'])
      Dir.chdir(File.join @base_repo_dir) do
        if overwrite
          @logger.debug 'overwriting our files during the rebase'
          successful_return = system("git rebase upstream/#{upstream_repo.master_branch} -X ours")
        else
          @logger.debug 'rebasing'
          successful_return = system("git rebase upstream/#{upstream_repo.master_branch}")
        end

        if successful_return
          [200, 'Successful merge']
        else
          [500, 'Merge conflict detected']
        end
      end
    end

    def remove_branch(branch_name)
      @logger.info "removing branch #{branch_name}"
      @git_repo.branch('master').checkout
      @git_repo.branch(branch_name).delete
    end

    def branches
      @logger.debug "Fetching local branches and notes"
      Open3.popen3('git show --format="||%d||%h||%N" --notes=pull $(git notes --ref=pull | awk "{ print $2 }") | awk "{ if ($1 ~ /\|\|/) { print $0 } }',
                   :chdir => File.absolute_path(base_repository_path)) do |_, stdout, stderr, wait_thr|
        exit_value = wait_thr.value
        @logger.debug "fetch exit status: #{exit_value}"
        error = stderr.readlines.join "\n"
        @logger.debug "fetch error: #{error}" unless error.empty?

        returns = []
        stdout.readlines.each do |line|
          _, branches, pull = line.split '||'
          branches = branches.strip.gsub(/[()]/, '').split(',').last.strip
          returns << {:pull => pull, :branch => branches}
        end

        returns
      end
    end

    def push(remote = 'origin')
      @logger.info "pushing to #{remote}"
      system("git push #{remote} HEAD")
    end

    def pull_request(title, body)
      github = create_github_client
      upstream_repo = Octokit::Repository.from_url @settings['repo']
      upstream_response = github.repository(upstream_repo)
      @logger.info "Issuing a pull request with title - #{title} and body #{body}"
      pull_request_result = github.create_pull_request(upstream_repo,
                                                       "#{upstream_response.owner.login}:#{upstream_response.master_branch}",
                                                       "#{@settings['username']}:#{@git_repo.lib.branch_current}", title, body)
      @git_repo.branch(upstream_response.master_branch).checkout
      pull_request_result['html_url']
    end

    def file_content(file)
      @logger.info "reading contents of file #{file.to_s}"

      file_path = File.join(base_repository_path, file)

      return '' unless File.exists? file_path

      if `file --mime-encoding -b #{file_path}` =~ /binary/
        "data:#{`file --mime-type -b #{file_path}`.strip};base64,#{Base64.encode64(File.open(file_path, 'rb').read)}"
      else
        File.open(file_path, 'r').read
      end
    end

    def file_info(path, dir = '')
      path = Pathname.new(path)
      path = Pathname.new(File.join(base_repository_path, dir, path.basename)) unless File.exists? path
      { :location => path.basename.to_s, :directory => path.directory?,
        :path_to_root => path.relative_path_from(Pathname.new base_repository_path).dirname.to_s }
    end

    def log(count = 30)
      @logger.info "retrieving the last #{count} log entries"
      @git_repo.log count
    end

  private

  def create_github_client
    Octokit::Client.new(:login => @settings['username'], :oauth_token => @settings['oauth_token'])
  end

  end
end

