class WeeklyGoal
	include DataMapper::Resource
	property :id, Serial
	property :limit_amount, Float, :required=>true, :default=>0.00
	property :start_date, DateTime
	property :end_date, DateTime
	belongs_to :user
end
