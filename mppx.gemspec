# frozen_string_literal: true

require_relative "lib/mppx/version"

Gem::Specification.new do |spec|
  spec.name = "mppx"
  spec.version = Mppx::VERSION
  spec.authors = ["CJ Avilla"]
  spec.email = ["wave@cjav.dev"]
  spec.summary = "Ruby implementation of the Machine Payments Protocol SDK"
  spec.description = "Implements the Payment HTTP Authentication Scheme (HTTP 402) for payment-gated APIs."
  spec.homepage = "https://github.com/cjavdev/mppx-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/cjavdev/mppx-rb",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rake", "~> 13.0"
end
