$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = 'bbbot-ruby'
  s.version = '0.0.1'
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE']
  s.summary = 'Ruby wrapper for bbbot (https://github.com/mconf/bbbot-ruby)'
  s.description = s.summary
  s.authors = ['Leonardo Crauss Daronco']
  s.email = ['leonardodaronco@gmail.com']
  s.homepage = "https://github.com/mconf/bbbot-ruby"
  s.bindir = "bin"
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
end
