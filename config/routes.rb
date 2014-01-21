Spree::Core::Engine.routes.prepend do
  get '/unified_payments/new', :to => "unified_payments#new", :as => :new_unified_transaction
  post '/unified_payments/create', :to => "unified_payments#create", :as => :create_unified_transaction
  post '/unified_payments/canceled', :to => "unified_payments#canceled"
  post '/unified_payments/declined', :to => "unified_payments#declined"
  post '/unified_payments/approved', :to => "unified_payments#approved"
  get '/unified_payments/declined', :to => redirect{ |p, request| '/' }

  namespace :admin do
    get '/unified_payments', :to => "unified_payments#index"
    get '/unified_payments/receipt/:number', :to => "unified_payments#receipt", :as => :unified_payments_receipt
    post '/unified_payments/query_gateway', :to => "unified_payments#query_gateway", :as => :unified_payments_query_gateway
  end
end