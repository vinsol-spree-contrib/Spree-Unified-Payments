module SpreeUnifiedPayment
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      def add_javascripts
        append_file 'app/assets/javascripts/admin/all.js', "//= require admin/spree_unified_payment\n"
      end

      def add_stylesheets
        inject_into_file 'app/assets/stylesheets/store/all.css', " *= require store/spree_unified_payment\n", :before => /\*\//, :verbose => true
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_unified_payment'
      end

      def run_migrations
        run 'bundle exec rake db:migrate'
      end
    end
  end
end
