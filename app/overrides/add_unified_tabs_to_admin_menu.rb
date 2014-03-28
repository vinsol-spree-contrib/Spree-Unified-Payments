Deface::Override.new(:virtual_path => "spree/admin/shared/_menu",
                     :name => "Add Unified tab to menu",
                     :insert_bottom => "[data-hook='admin_tabs']",
                     :text => " <%= tab( :UnifiedPayments , :url => admin_unified_payments_path) %>",
                     :sequence => {:after => "promo_admin_tabs"},
                     :disabled => false)
