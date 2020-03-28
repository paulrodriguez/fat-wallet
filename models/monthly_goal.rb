class MonthlyGoal
	include DataMapper::Resource
	property :id, Serial
	property :limit_amount, Float, :required=>true, :default=>0.00
	property :year, Integer
	property :month, Integer
	belongs_to :user
end
