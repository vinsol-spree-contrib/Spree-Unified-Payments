Spree::Core::Engine.routes.draw do
  get '/unified_payments' => "unified_payments#index", as: :unified_payments
  get '/unified_payments/new' => "unified_payments#new", as: :new_unified_transaction
  post '/unified_payments/create' => "unified_payments#create", as: :create_unified_transaction
  post '/unified_payments/canceled' => "unified_payments#canceled", as: :canceled_unified_payments
  post '/unified_payments/declined' => "unified_payments#declined", as: :declined_unified_payments
  post '/unified_payments/approved' => "unified_payments#approved", as: :approved_unified_payments
  
  get 'admin/unified_payments' => "admin/unified_payments#index"
  get 'admin/unified_payments/receipt/:transaction_id' => "admin/unified_payments#receipt", as: :admin_unified_payments_receipt
  post 'admin/unified_payments/query_gateway' => "admin/unified_payments#query_gateway", as: :admin_unified_payments_query_gateway
  
  get '/unified_payments/declined', :to => redirect{ |p, request| '/' }  
end