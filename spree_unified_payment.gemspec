Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name = "spree_unified_payment"

  #[TODO_CR] Lets name this version 1.0.0
  #[MK] Its suggested to keep extension version same as spree version used in spree extension guide
  s.version = "2.0.3"
  s.author = "Manish Kangia"

  #[TODO_CR] We need to update this date each time we ar emaking new build.
  # Else we can leave this blank
  #[MK] Please remove post review. Commented for now
  # s.date = "2014-01-21"
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com' 

  s.summary = "Integrate payment using UnifiedPayment service"
  s.description = "Enable spree store to allow payment via UnifiedPayment"

  s.required_rubygems_version = ">=2.0.0"

  s.files = `git ls-files`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency('spree_core', '~> 2.0.0')
  s.add_dependency 'unified_payment'
  s.add_dependency 'spree_wallet'
  s.add_dependency 'delayed_job_active_record'
end