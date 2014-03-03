Deface::Override.new(:virtual_path => "spree/shared/_nav_bar",
                     :name => "User link to view UnifiedPayment Transactions",
                     :insert_before => "li#search-bar",
                     :partial => "spree/shared/unified_payments_link",
                     :disabled => false, 
                     :original => 'eb3fa668cd98b6a1c75c36420ef1b238a1fc55ac')