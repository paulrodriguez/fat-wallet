require 'sinatra'
require 'sinatra/flash'
require 'dm-sqlite-adapter'
require 'dm-serializer'
require 'digest/sha1'
#require 'sinatra/base'
require 'dotenv/load'
require 'data_mapper'
require File.dirname(__FILE__)+'/models.rb'
require 'json'

set :session_secret, "328479283uf923fu8932fu923uf9832f23f232"
enable :sessions

module CurrentWeek
  # 1=>Monday, 2=>Tuesday, 3=>Wednesday, 4=>Thursday, 5 => Friday, 6 => Saturday, 7=>Sunday
  def getWeekDate(day)
    @currDate = Date.today
    @currWeekDate = @currDate-@currDate.cwday+day+getDaysFromCurrentDate
  end
  #gets the date of the monday of the current week we are viewing
  def getStartWeekDate(counter=0)
    @currDate = Date.today
    @date = @currDate-@currDate.cwday+1+(counter*7)
  end
  #gets the date of the Sunday of the current week we are viewing
  def getEndWeekDate(counter=0)
    @currDate = Date.today
    @date = @currDate-@currDate.cwday+7+(counter*7)
  end
  def getDaysFromCurrentDate
    if !session[:days_from_current_date].nil?
      session[:days_from_current_date].to_i
    else
      0
    end
  end

  def setDaysFromCurrentDate(days_to_add)
    session[:days_from_current_date] = days_to_add
  end
end

module CurrentMonth
    def getCurrentMonth(counter)
        @currentMonth = Date.today.next_month(counter)
    end

    def getCurrentMonthStartDate(counter=0)
        @curr_month = getCurrentMonth(counter)
        @start_date = Date.civil(@curr_month.year,@curr_month.month,1)
        @start_date
    end

    def getCurrentMonthEndDate(counter=0)
        @curr_motnh = getCurrentMonth(counter)
        @end_date = getCurrentMonthStartDate(counter).next_month-1
        @end_date
    end

    def getMonthsFromCurrentDate
        if !sessions[:months_to_add].nil?
            sessions[:months_to_add].to_i
        else
            0
        end
    end

    def setMonthsFromCurrentDate(months_to_add)
        session[:months_to_add] = months_to_add
    end
end

module ViewTypeDate
  def getViewTypeDate
    if !session[:view_type].nil?
      session[:view_type]
    else
      'week'
    end
  end

  def setViewTypeDate(view_type='week')
    session[:view_type] = view_type
  end

  def getDateCounter
    if !session[:date_counter].nil?
      session[:date_counter].to_i
    else
      0
    end
  end

  def setDateCounter(counter=0)
    session[:date_counter] = counter
  end

  def getStartDate
    if self.getViewTypeDate=='week'
      return getStartWeekDate(getDateCounter)
    elsif self.getViewTypeDate=='month'
      return getCurrentMonthStartDate(getDateCounter)
    end
    return Date.today
  end

  def getEndDate
    if self.getViewTypeDate=='week'
      return getEndWeekDate(getDateCounter)
    elsif self.getViewTypeDate=='month'
      return getCurrentMonthEndDate(getDateCounter)
    end
    return Date.today
  end
end


helpers CurrentWeek,CurrentMonth,ViewTypeDate

enable :sessions

#for all routes except '/login' check if session with username is
before %r{(?!(/login|/register))} do
  puts session[:username]
  if session[:username].nil?
		redirect '/login'
	end
end

# if already logged in, then redirect to index page
before %r{/login} do
  if !session[:username].nil?
    redirect '/'
  end
end

before %r{.+\.json} do
    content_type 'application/json'
end

##############################################
### LOGIN INFORMATION
#############################################
get '/logout' do
  if !session[:username].nil?
    session.destroy
  end
  redirect '/login'
end
get '/login' do
	erb :login
end

post '/login' do
  errors = Array.new
	@user = User.first(:username=>params[:username])
	if !@user.nil?
		if @user.password==Digest::SHA1.base64digest(params[:password])
      session[:username] = @user.username
      session[:user_id] = @user.id
      redirect "/"
    else
      errors << "incorrect password"
      flash[:error] = errors
    end
	else
    errors << "no account found with the specified username"
    flash[:error] = errors
	end
  erb :login
end

post '/register' do
  @new_user =User.new
  @new_user.username = params[:username]
  @new_user.password = Digest::SHA1.base64digest(params[:password])
  @new_user.email    = params[:email]
  @new_user.created_at = DateTime.now
  @new_user.updated_at = DateTime.now
  if @new_user.save
    session[:username] = @new_user.username
    session[:user_id] = @new_user.id
    flash[:success] = "Account successfully created"
    redirect "/"
  else
    errors = Array.new
    errors << "unable to create account"
    @new_user.errors.each do |e|

      errors << e.to_s
    end
    flash[:error] = errors
  end

  redirect "/login"
end


####################################################
### LOGIN INFORMATION
###################################################

get '/' do
	content_type 'html'
  @script = "js/app.js"
  @currDate = Date.today
  @weekStart = getStartDate
  @weekEnd = getEndDate
	erb :index, :layout=>:"layouts/main"

end

get '/account' do
  content_type 'html'
  @user = User.first(:username=>session[:username])
  erb :account
end

put '/account.json' do
  {:p=>params}.to_json
end

get '/date_range.json' do


end

get '/month_dates.json' do
    @currMonthStart = getCurrMonthStartDate
    @currMonthEnd = getCurrMonthEndDate
    {:month_start=>@currMonthStart, :month_end=>@currMonthEnd,:months_from_current_date=>getMonthsFromCurrentDate}.to_json
end

post '/months_to_add.json' do
    if(params[:months_to_add])
        months_from_current_date = getMonthsFromCurrentDate+params[:months_to_add].to_i
    end
end

# get '/week_dates.json' do
#   @startDate = getStartDate
#   @endDate = getEndDate
#   {:date_range=>@startDate.strftime("%m/%d/%Y")+" - "+@endDate.strftime("%m/%d/%Y"),
#   :start_date=>@startDate,:end_date=>@endDate,
#   :date_counter=>getDateCounter}.to_json
# end
#
#
#
# post '/week_dates.json' do
#   if(params[:date_counter])
#     counter = getDateCounter+params[:date_counter].to_i
#     setDateCounter(counter)
#   end
#
#   @currWeekDateStart = getWeekDate(1)
#   @currWeekDateEnd = getWeekDate(7)
#   {:full_week=>@currWeekDateStart.strftime("%m/%d/%Y")+" - "+@currWeekDateEnd.strftime("%m/%d/%Y"),
#   :current_week_start=>@currWeekDateStart,:current_week_end=>@currWeekDateEnd,
#   :days_from_current_date=>getDaysFromCurrentDate}.to_json
# end

get '/weekly_goals.json' do
  @weekly_goal = WeeklyGoal.first(:user_id=>session[:user_id],:start_date.gte=>getWeekDate(1),:end_date.lte=>getWeekDate(7))
  if(@weekly_goal.nil?)
    {:status=>"failure"}.to_json
  else
    {:weekly_goal=>@weekly_goal,:status=>"success"}.to_json
  end
end

post '/weekly_goals.json' do
  @weekly_goal = WeeklyGoal.new

  @weekly_goal.start_date = getWeekDate(1)
  @weekly_goal.end_date = getWeekDate(7)
  @weekly_goal.user_id = session[:user_id]
  @weekly_goal.limit_amount = params[:limit_amount]

  if @weekly_goal.save
    {:weekly_goal=>@weekly_goal,:status=>"success"}.to_json
  else
    {:errors=>@weekly_goal.errors.full_messages,:status=>"failure"}.to_json
  end
end

put '/weekly_goals.json' do
  @weekly_goal = WeeklyGoal.get(params[:id])
  if @weekly_goal.nil?
    {:errors=>Array.new("invalid id"),:status=>"failure"}.to_json
  else
    @weekly_goal.limit_amount = params[:limit_amount]
    if @weekly_goal.save
      {:weekly_goal=>@weekly_goal,:status=>"success"}.to_json
    else
      {:errors=>@weekly_goal.errors.full_messages,:status=>"failure"}.to_json
    end
  end
end





################################################
# START VIEW DATES API
################################################
get '/view_dates.json' do
  #get start and end dates
  @startDate = getStartDate
  @endDate = getEndDate
  #return json response with the date range, counter and other stuff
  {:date_range=>@startDate.strftime("%m/%d/%Y")+" - "+@endDate.strftime("%m/%d/%Y"),
  :start_date=>@startDate,:end_date=>@endDate,
  :date_counter=>getDateCounter,:date_view_type=>getViewTypeDate}.to_json
end


post '/view_dates.json' do
  if(params[:date_counter])
    days_from_current_date = getDateCounter+params[:date_counter].to_i
    setDateCounter(days_from_current_date)
  end
  if(params[:date_view_type])
    setViewTypeDate(params[:date_view_type])
    setDateCounter(0)
  end

  #get start and end dates
  @startDate = getStartDate
  @endDate = getEndDate
  #return json response with the date range, counter and other stuff
  {:date_range=>@startDate.strftime("%m/%d/%Y")+" - "+@endDate.strftime("%m/%d/%Y"),
  :start_date=>@startDate,:end_date=>@endDate,
  :date_counter=>getDateCounter,:date_view_type=>getViewTypeDate}.to_json
end

################################################
# END VIEW DATES API
################################################



################################################
# START transactions API
################################################
get '/transactions.json' do
  @startDate = getStartDate
  @endDate = getEndDate
	@transactions = Transaction.all(:transaction_date.gte=>@startDate,:transaction_date.lte=>@endDate,:user_id=>session[:user_id])
  @transaction_items = Hash.new
  @transactions.each do |t|
    @transaction_items[t.id] = t.transactionItems
  end
  #@transactionItems = TransactionItem.all()
  {:transactions=>@transactions,:transaction_items=>@transaction_items,
    :start_date=>@startDate,:end_date=>@endDate}.to_json
	#@transactions.to_json
end

post '/transactions.json' do
  @transaction = Transaction.new
  @transaction.description = params[:description]
  @transaction.grand_total = params[:grand_total]
  @transaction.discount_total = params[:discount_total]
  @transaction.tax_total = params[:tax_total]
  @transaction.tax_rate = params[:tax_rate]
  @transaction.transaction_date = Date.strptime(params[:transaction_date], "%m/%d/%Y").to_datetime
  @transaction.created_at = DateTime.now
  @transaction.updated_at = DateTime.now
  @transaction.user_id    = session[:user_id]

  if @transaction.save
    {:transaction=>@transaction,:status=>"success",:type=>"new"}.to_json
  else
    {:errors=>@transaction.errors.full_messages,:transaction=>@transaction,:status=>"failure",'user':session[:user_id]}.to_json
  end
end

put '/transactions.json' do
    @transaction = Transaction.get(params[:id])
    if @transaction.nil?
      {:status=>"failure"}.to_json
    else
      @transaction.description = params[:description]
      @transaction.grand_total = params[:grand_total]
      @transaction.discount_total = params[:discount_total]
      @transaction.tax_total = params[:tax_total]
      @transaction.tax_rate = params[:tax_rate]
      @transaction.transaction_date = Date.strptime(params[:transaction_date], "%m/%d/%Y").to_datetime#DateTime.parse(params[:transaction_date])
      @transaction.updated_at = DateTime.now

      if @transaction.save
        {:transaction=>@transaction,:status=>"success",:type=>'update'}.to_json
      else
        {:errors=>@transaction.errors.full_messages,:transaction=>@transaction,:status=>"failure"}.to_json
      end
    end
end

delete '/transactions.json' do
  @transaction = Transaction.get(params[:id])
  if @transaction.destroy
    {:status=>'success'}.to_json
  else
    {:status=>"failure"}.to_json
  end
end


################################################
# END transactions API
################################################

get '/transaction_items.json' do
  @transaction = Transaction.get(params[:transaction_id])
  if @transaction.nil?
    {:status=>"failure"}.to_json
  else
    {:transaction_items=>@transaction.transactionItems,:status=>"success"}.to_json
  end
end

post '/transaction_items.json' do
  @transaction = Transaction.get(params[:transaction_id])
  if @transaction.nil?
    {:status=>"failure"}.to_json
  else
    @transactionItem = TransactionItem.new
    @transactionItem.description = params[:description]
    @transactionItem.grand_total = params[:grand_total]
    @transactionItem.discount_total = params[:discount_total]
    @transactionItem.tax_total = params[:tax_total]
    @transactionItem.quantity = params[:quantity]
    @transactionItem.created_at = DateTime.now
    @transactionItem.updated_at = DateTime.now
    @transaction.transactionItems << @transactionItem
    if @transactionItem.save
      {:transaction_item=>@transactionItem,:status=>"success",:method=>"add"}.to_json
    else
      {:errors=>@transactionItem.errors.full_messages,:transaction_item=>@transactionItem,:status=>"failure"}.to_json
    end
  end
end

put '/transaction_items.json' do
  @transaction_item = TransactionItem.get(params[:id])
  if @transaction_item.nil?
    {:status=>"failure"}.to_json
  else
    @transaction_item.description = params[:description]
    @transaction_item.grand_total = params[:grand_total]
    @transaction_item.discount_total = params[:discount_total]
    @transaction_item.tax_total = params[:tax_total]
    @transaction_item.quantity = params[:quantity]
    @transaction_item.updated_at = DateTime.now

    if @transaction_item.save
      {:transaction_item=>@transaction_item,:status=>"success"}.to_json
    else
      {:errors=>@transactionItem.errors.full_messages,:status=>"failure"}.to_json
    end
  end
end

delete '/transaction_items.json' do
  @transaction_item = TransactionItem.get(params[:id])
  if @transaction_item.nil?
    {:status=>"failure"}.to_json
  else
    if @transaction_item.destroy
      {:status=>"success",:method=>"delete"}.to_json
    else
      {:status=>"failure"}.to_json
    end
  end
end



get '/getdate' do
	{:date=>DateTime.now}.to_json
end

get '/test' do
#     @prev_month = Date.today.next_month(-12)
#     @next_month = Date.civil(@prev_month.year,@prev_month.month,1).next_month-1
#     @start_month_date = Date.civil(@prev_month.year,@prev_month.month,1).to_s
#     @end_month_date = Date.civil(@next_month.year,@next_month.month,@next_month.day).to_s
#     @start_month_date+ "--"+@end_month_dat

    self.getStartDate.to_s + " - "+self.getEndDate.to_s
end
