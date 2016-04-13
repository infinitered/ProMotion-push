# -*- encoding: utf-8 -*-
Gem::Specification.new do |spec|
  spec.name          = "ProMotion-push"
  spec.version       = "0.4.0"
  spec.authors       = ["Jamon Holmgren"]
  spec.email         = ["jamon@infinite.red"]
  spec.description   = %q{Adds push notification support to ProMotion.}
  spec.summary       = %q{Adds push notification support to ProMotion.}
  spec.homepage      = "https://github.com/infinitered/ProMotion-push"
  spec.license       = "MIT"

  files = []
  files << 'README.md'
  files.concat(Dir.glob('lib/**/*.rb'))
  spec.files         = files
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ProMotion", "~> 2.0"
  spec.add_development_dependency "motion-stump", "~> 0.3"
  spec.add_development_dependency "motion-redgreen", "~> 1.0"
  spec.add_development_dependency "rake"
end
