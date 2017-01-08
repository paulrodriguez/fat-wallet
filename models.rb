DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://"+File.dirname(__FILE__)+"/FatWallet.db")
class User
	include DataMapper::Resource
	property :id, Serial
	property :username, String, :required=>true
	property :email, Text, :required => true, :unique => true,
		:format   => :email_address,
    :messages => {
      :presence  => "We need your email address.",
      :is_unique => "We already have that email.",
      :format    => "Email address is invalid."
    }

	property :password, Text, :required=>true, :default=>""
	property :created_at, DateTime
	property :updated_at, DateTime

	has n, :transactions
	has n, :weeklyGoals
	has n, :monthlyGoals
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

	belongs_to :user
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

class WeeklyGoal
	include DataMapper::Resource
	property :id, Serial
	property :limit_amount, Float, :required=>true, :default=>0.00
	property :start_date, DateTime
	property :end_date, DateTime
	belongs_to :user
end

class MonthlyGoal
	include DataMapper::Resource
	property :id, Serial
	property :limit_amount, Float, :required=>true, :default=>0.00
	property :year, Integer
	property :month, Integer
	belongs_to :user
end

DataMapper.auto_upgrade!
