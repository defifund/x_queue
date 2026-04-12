# frozen_string_literal: true

require_relative "lib/x_queue/version"

Gem::Specification.new do |spec|
  spec.name = "x_queue"
  spec.version = XQueue::VERSION
  spec.authors = ["Bob Wang"]
  spec.email = ["7777@hey.com"]

  spec.summary = "Schedule and post tweet threads to X (Twitter) from any Rails app."
  spec.description = "A Rails engine that manages tweet scheduling, thread chaining, and posting to the X API. Supports multi-account, polymorphic source association, and configurable delays."
  spec.homepage = "https://github.com/defifund/x_queue"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/defifund/x_queue"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .standard.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "x", ">= 0.14"
end
