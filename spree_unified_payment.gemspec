Gem::Specification.new do |s|
  s.platform  = Gem::Platform::RUBY
  s.name      = "spree_unified_payment"
  s.version   = "1.0.0"
  s.author    = ["Manish Kangia", "Sushant Mittal"
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com'
  s.license   = 'MIT' 

  s.summary     = "Integrate payment using UnifiedPayment service"
  s.description = "Enable spree store to allow payment via UnifiedPayment"

  s.required_rubygems_version = ">=2.0.0"

  s.files = `git ls-files`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency('spree_core', '~> 2.0.0')
  s.add_dependency 'unified_payment', '1.0.0'
  s.add_dependency 'spree_wallet', '~> 2.0.3'
  s.add_dependency 'delayed_job_active_record', '~> 4.0.0'
end