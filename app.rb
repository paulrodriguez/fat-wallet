require 'sinatra'
require 'sinatra/flash'
require 'dm-serializer'
require 'digest/sha1'
#require 'sinatra/base'
require 'data_mapper'
require File.dirname(__FILE__)+'/models.rb'
require 'json'

module CurrentWeek
  # 1=>Monday, 2=>Tuesday, 3=>Wednesday, 4=>Thursday, 5 => Friday, 6 => Saturday, 7=>Sunday
  def getWeekDate(day)
    @currDate = Date.today
    @currWeekDate = @currDate-@currDate.cwday+day+getDaysFromCurrentDate
  end
  def getCurrentMonth
    @currDate = Date.today.prev_month(getMonthsToAdd)
  end
  def getMonthsToAdd
    if !session[:months_to_add].nil?
      session[:months_to_add].to_i
    else
      0
    end
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
helpers CurrentWeek
enable :sessions

#for all routes except '/login' check if session with username is
before %r{^(?!(/login|/register)$)} do

  if session[:username].nil?
		redirect '/login'
	end
end

# if already logged in, then redirect to index page
before %r{^/login$} do
  if !session[:username].nil?
    redirect '/'
  end
end

before %r{.+\.json$} do
    content_type 'application/json'
end
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

get '/' do
	content_type 'html'
  @script = "js/app.js"
  @currDate = Date.today
  @weekStart = getWeekDate(1)
  @weekEnd = getWeekDate(7)
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

get '/week_dates.json' do
  @currWeekDateStart = getWeekDate(1)
  @currWeekDateEnd = getWeekDate(7)
  {:full_week=>@currWeekDateStart.strftime("%m/%d/%Y")+" - "+@currWeekDateEnd.strftime("%m/%d/%Y"),
  :current_week_start=>@currWeekDateStart,:current_week_end=>@currWeekDateEnd,
  :days_from_current_date=>getDaysFromCurrentDate}.to_json
end

post '/week_dates.json' do
  if(params[:days_to_add])
    days_from_current_date = getDaysFromCurrentDate+params[:days_to_add].to_i
    setDaysFromCurrentDate(days_from_current_date)
  end

  @currWeekDateStart = getWeekDate(1)
  @currWeekDateEnd = getWeekDate(7)
  {:full_week=>@currWeekDateStart.strftime("%m/%d/%Y")+" - "+@currWeekDateEnd.strftime("%m/%d/%Y"),
  :current_week_start=>@currWeekDateStart,:current_week_end=>@currWeekDateEnd,
  :days_from_current_date=>getDaysFromCurrentDate}.to_json
end

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

get '/transactions.json' do
  @currWeekDateStart = getWeekDate(1)
  @currWeekDateEnd = getWeekDate(7)
	@transactions = Transaction.all(:transaction_date.gte=>@currWeekDateStart,:transaction_date.lte=>@currWeekDateEnd,:user_id=>session[:user_id])
  @transaction_items = Hash.new
  @transactions.each do |t|
    @transaction_items[t.id] = t.transactionItems
  end
  #@transactionItems = TransactionItem.all()
  {:transactions=>@transactions,:transaction_items=>@transaction_items}.to_json
	#@transactions.to_json
end

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

post '/transactions.json' do
  @transaction = Transaction.new
  @transaction.description = params[:description]
  @transaction.grand_total = params[:grand_total]
  @transaction.discount_total = params[:discount_total]
  @transaction.tax_total = params[:tax_total]
  @transaction.transaction_date = Date.strptime(params[:transaction_date], "%m/%d/%Y").to_datetime
  @transaction.created_at = DateTime.now
  @transaction.updated_at = DateTime.now
  @transaction.user_id    = session[:user_id]

  if @transaction.save
    {:transaction=>@transaction,:status=>"success"}.to_json
  else
    {:errors=>@transaction.errors.full_messages,:transaction=>@transaction,:status=>"failure"}.to_json
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
      @transaction.transaction_date = DateTime.parse(params[:transaction_date])
      @transaction.updated_at = DateTime.now

      if @transaction.save
        {:transaction=>@transaction,:status=>"success"}.to_json
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

get '/getdate' do
	{:date=>DateTime.now}.to_json
end
