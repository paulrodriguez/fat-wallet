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
