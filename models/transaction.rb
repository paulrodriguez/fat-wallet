class Transaction
  include DataMapper::Resource
  property :id, Serial
  property :description, Text, :required=>true
  property :transaction_date, DateTime
  property :grand_total, Float
  property :discount_total, Float, :required=>false, :default=>0.00
  property :tax_total,Float, :required=>false, :default=>0.00
	property :tax_rate,Float, :required=>false, :default=>0.00
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :transactionItems

	belongs_to :user
end
