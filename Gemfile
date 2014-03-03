source "https://rubygems.org"
gem 'rails', '3.2.16'
gem 'mysql2'
gem 'sqlite3'


gem 'spree', :git => 'git://github.com/spree/spree.git', :tag => 'v2.0.3'
gem 'spree_wallet', :git => 'git://github.com/vinsol/spree_wallet.git'
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '2-0-stable'

gem 'unified_payment', :git => "git@github.com:vinsol/Unified-Payments.git", :branch => 'master', :ref => 'd073d87e425609975ba4580323260c1fcc83ab86'
gem 'delayed_job_active_record', :tag => 'v4.0.0'

group :test do
  gem 'rspec-rails', '~> 2.10'
  gem 'shoulda-matchers', '2.2.0'
  gem 'simplecov', :require => false
  gem 'database_cleaner'
  gem 'rspec-html-matchers'
end
gemspec
