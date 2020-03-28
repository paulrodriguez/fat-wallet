class TransactionItem
  include DataMapper::Resource
  property :id, Serial
  property :description, Text, :required=>true
  property :grand_total, Float
  property :discount_total,Float, :required=>false
  property :tax_total, Float, :required=>false
  property :created_at, DateTime
  property :updated_at, DateTime
	property :quantity, Integer, :required=>true, :default=>1
  belongs_to :transaction
end
