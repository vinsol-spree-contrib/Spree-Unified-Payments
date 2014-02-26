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
Usage
---------
Customer :

Customer can pay via UnifiedPayment payment method at Checkout and can also see the list of UnifiedPayment Transactions initiated by them. 

If a transaction is completed but the order fails to complete, the amount paid by the customer is added to the customer's account which he can use in future so that the user does not get stuck while making the payment.

Admin :

Admin can see the list of UnifiedPayment Transactions initiated by customers under admin section.

Admin can also ping UnifiedPayment gateway for an updated status of a transaction and the transaction is then updated accordingly.

Testing
---------
Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.
```ruby
bundle
bundle exec rake test_app
bundle exec rspec spec
```

Credits
-------

[![vinsol.com: Ruby on Rails, iOS and Android developers](http://vinsol.com/vin_logo.png "Ruby on Rails, iOS and Android developers")](http://vinsol.com)

Copyright (c) 2014 [vinsol.com](http://vinsol.com "Ruby on Rails, iOS and Android developers"), released under the New MIT License
