source "https://rubygems.org"
gem 'rails', '4.0.3'
gem 'mysql2'
gem 'sqlite3'

gem 'coffee-script'
gem 'spree', :git => 'https://github.com/spree/spree.git', :tag => 'v2.2.0'

# Provides basic authentication functionality for testing parts of your engine
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', :branch => '2-2-stable'

gem 'spree_wallet', :git => 'git://github.com/vinsol/spree_wallet.git', branch: 'master', ref: 'e963563a45af410a20b863f6792b5da0613961dc'

gem 'unified_payment', github: 'vinsol/Unified-Payments', branch: 'upgrade_rails4'

gem 'delayed_job_active_record', :tag => 'v4.0.0'

group :test do
  gem 'rspec-rails', '~> 2.10'
  gem 'shoulda-matchers', '2.2.0'
  gem 'simplecov', :require => false
  gem 'database_cleaner'
  gem 'rspec-html-matchers'
end
gemspec
