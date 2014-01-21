Spree-Unified-Payments
================
Enable spree store to allow payment via UnifiedPayment

Dependencies
================

1) gem unified_payment
    gem 'unified_payment', :git => "git@github.com:vinsol/Unified-Payments.git"

2) delayed_job:
    gem 'delayed_job_active_record'

3) spree_wallet:
    gem 'spree_wallet', :git => 'git://github.com/vinsol/spree_wallet.git'


Set Up
================

Add To Gemfile:

1)gem 'spree_unified_payment', :git => "git@github.com:vinsol/Spree-Unified-Payments.git"

run bundle exec rails g spree_unified_payment:install