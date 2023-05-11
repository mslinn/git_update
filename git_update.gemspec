require_relative 'lib/git_update/version'

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  github = 'https://github.com/mslinn/git_update'

  spec.authors = ['Mike Slinn']
  spec.bindir = 'bindir'
  spec.description = <<~END_OF_DESC
    Installs the git-update command, which scans git directory trees and updates them.
    Directories containing a file called .ignore are ignored.
  END_OF_DESC
  spec.email = ['mslinn@mslinn.com']
  spec.executables = %w[git-update]
  spec.files = Dir[
    '{bindir,lib}/**/*',
    '.rubocop.yml',
    'LICENSE.*',
    'Rakefile',
    '*.gemspec',
    '*.md'
  ]
  spec.homepage = 'https://www.mslinn.com/git/1500-update-repos.html'
  spec.license = 'MIT'
  spec.metadata = {
    'allowed_push_host' => 'https://rubygems.org',
    'bug_tracker_uri'   => "#{github}/issues",
    'changelog_uri'     => "#{github}/CHANGELOG.md",
    'homepage_uri'      => spec.homepage,
    'source_code_uri'   => github,
  }
  spec.name = 'git_update'
  spec.post_install_message = <<~END_MESSAGE

    Thanks for installing #{spec.name}!

  END_MESSAGE
  spec.required_ruby_version = '>= 3.0.0'
  spec.summary = 'Installs the git-update command, which updates git directory trees.'
  spec.version = GitUpdateVersion::VERSION

  spec.add_dependency 'concurrent'
  spec.add_dependency 'rainbow'
  spec.add_dependency 'rugged'
end
