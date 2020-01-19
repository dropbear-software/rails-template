require "bundler"
require "fileutils"
require "shellwords"
require "tmpdir"
require "thor"

# You shouldn't need to change anything beyond these constrants
RAILS_REQUIREMENT = "~> 6.0.0".freeze
TEMPLATE_GITHUB_REPO = "https://github.com/dropbear-software/rails-template.git"

class ApplicationInfo
  attr_accessor :application_name, :github_repo

  def initialize(application_name:, github_repo: nil)
    @application_name = application_name
    @github_repo = github_repo
  end
end

class SetupEnvironment

  attr_accessor :status

  def initialize(rails_version:)
    @valid = true
    assert_minimum_rails_version(rails_version)
    add_template_repository_to_source_path

    raise "You don't have a valid execution environment" unless @status
  end

  private

  def assert_minimum_rails_version(rails_version)
    requirement = Gem::Requirement.new(rails_version)
    rails_version = Gem::Version.new(Rails::VERSION::STRING)
    return if requirement.satisfied_by?(rails_version)

    prompt = "This template requires Rails #{rails_version}. "\
            "You are using #{rails_version}. Continue anyway?"
    # exit 1 if no?(prompt)
    @status = false if no?(prompt)
  end

  def assert_postgresql
    return if IO.read("Gemfile") =~ /^\s*gem ['"]pg['"]/
    @staus = false;
    fail Rails::Generators::Error,
         "This template requires PostgreSQL, "\
         "but the pg gem isn’t present in your Gemfile."
  end

  # Add this template directory to source_paths so that Thor actions like
  # copy_file and template resolve against our source files. If this file was
  # invoked remotely via HTTP, that means the files are not present locally.
  # In that case, use `git clone` to download them to a local temporary dir.
  def add_template_repository_to_source_path
    if __FILE__ =~ %r{\Ahttps?://}
      
      source_paths.unshift(tempdir = Dir.mktmpdir("rails-template-"))
      at_exit { FileUtils.remove_entry(tempdir) }
      git clone: [
        "--quiet",
        TEMPLATE_GITHUB_REPO,
        tempdir
      ].map(&:shellescape).join(" ")

      if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
        Dir.chdir(tempdir) { git checkout: branch }
      end
    else
      source_paths.unshift(File.dirname(__FILE__))
    end
  end
end

myenv = SetupEnvironment.new(rails_version: RAILS_REQUIREMENT)
