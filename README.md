Spree-Unified-Payments [![Code Climate](https://codeclimate.com/github/vinsol/Spree-Unified-Payments.png)](https://codeclimate.com/github/vinsol/Spree-Unified-Payments)
================
Enable spree store to allow payment via UnifiedPayment

Dependencies
================

1) gem unified_payment
```ruby
gem 'unified_payment', :git => "git@github.com:vinsol/Unified-Payments.git"
```
2) delayed_job
```ruby
gem 'delayed_job_active_record'
```
3) spree_wallet
```ruby
gem 'spree_wallet', :git => 'git://github.com/vinsol/spree_wallet.git'
```

Set Up
================

Add To Gemfile:
```ruby
gem 'spree_unified_payment', :git => "git@github.com:vinsol/Spree-Unified-Payments.git"
```

And run below command
```ruby
bundle exec rails g spree_unified_payment:install
```

Credits
-------

[![vinsol.com: Ruby on Rails, iOS and Android developers](http://vinsol.com/vin_logo.png "Ruby on Rails, iOS and Android developers")](http://vinsol.com)

Copyright (c) 2014 [vinsol.com](http://vinsol.com "Ruby on Rails, iOS and Android developers"), released under the New MIT License
