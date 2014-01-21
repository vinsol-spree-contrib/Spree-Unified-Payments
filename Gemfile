source "https://rubygems.org"
gem 'rails', '3.2.16'
gem 'mysql2'


gem 'spree', :git => 'git://github.com/spree/spree.git', :tag => 'v2.0.3'
gem 'spree_wallet', :git => 'git://github.com/vinsol/spree_wallet.git'
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '2-0-stable'

gem 'unified_payment', :git => "git@github.com:vinsol/Unified-Payments.git", :branch => 'master', :ref => '4ced91335fec2cf186c30b593d9a1f6083028748'
gem 'delayed_job_active_record', :tag => 'v4.0.0'

group :test do
  gem 'rspec-rails', '~> 2.10'
  gem 'shoulda-matchers', '2.2.0'
  gem 'simplecov', :require => false
  gem 'database_cleaner'
  gem 'rspec-html-matchers'
end
gemspec
