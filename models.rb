DataMapper.setup(:default, "sqlite://"+File.dirname(__FILE__)+"/FatWallet.db")
class User
	include DataMapper::Resource
	property :id, Serial
	property :username, String, :required=>true
	property :password, Text, :required=>true, :default=>""
	property :created_at, DateTime
	property :updated_at, DateTime
end

class Transaction
  include DataMapper::Resource
  property :id, Serial
  property :description, Text, :required=>true
  property :transaction_date, DateTime
  property :grand_total, Float
  property :discount_total, Float
  property :tax_total,Float
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :transactionItems
end

class TransactionItem
  include DataMapper::Resource
  property :id, Serial
  property :description, Text, :required=>true
  property :grand_total, Float
  property :discount_total,Float, :required=>false
  property :tax_total, Float, :required=>false
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :transaction
end

DataMapper.auto_upgrade!
