ActiveRecord::Schema.define :version => 0 do
  create_table "restfulie_models", :force => true do |t|
    t.column :status, :string
  end
  create_table "client_restfulie_models", :force => true do |t|
    t.column :status, :string
  end
end
ActiveRecord::Schema.define :version => 1 do
  create_table "orders", :force => true do |t|
  end
  create_table "client_orders", :force => true do |t|
  end
end
ActiveRecord::Schema.define :version => 2 do
  create_table "people", :force => true do |t|
  end
end
ActiveRecord::Schema.define :version => 3 do
  create_table "players", :force => true do |t|
    t.column :name, :string
  end
  create_table "teams", :force => true do |t|
  end
end
