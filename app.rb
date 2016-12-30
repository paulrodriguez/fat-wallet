require 'sinatra'
require 'sinatra/flash'
require 'dm-serializer'
#require 'sinatra/base'
require 'data_mapper'
require File.dirname(__FILE__)+'/models.rb'
require 'json'

module CurrentWeek
  def getWeekDate(day)
    @currDate = Date.today
    Date.commercial(@currDate.year,@currDate.cweek,day)
  end
end
helpers CurrentWeek
enable :sessions

#for all routes except '/login' check if session with username is
before %r{^(?!/login$)} do

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
	@user = User.first(:username=>params[:username])
	if !@user.nil?
		if @user.password==params[:password]
      session[:username] = @user.username
      redirect "/"
    else
      flash[:error] = "incorrect password"
    end
	else
    @new_user = User.new
    @new_user.username = params[:username]
    @new_user.password = params[:password]
    @new_user.created_at = DateTime.now
    @new_user.updated_at = DateTime.now
    if @new_user.save
      session[:username] = @new_user.username
      flash[:success] = "Account successfully created"
      redirect "/"
    else
      flash[:error] = "unable to created account"
    end
	end
  erb :login
end


get '/' do
	content_type 'html'
  @currDate = Date.today
  @weekStart = getWeekDate(1)
  @weekEnd = getWeekDate(7)
  #@weekStart = Date.commercial(@currDate.year,@currDate.cweek,1)
  #@weekEnd = Date.commercial(@currDate.year,@currDate.cweek,7)
	erb :index

end

get '/transactions.json' do
  @currWeekDateStart = getWeekDate(1)
  @currWeekDateEnd = getWeekDate(7)
	@transactions = Transaction.all(:transaction_date.gte=>@currWeekDateStart,:transaction_date.lte=>@currWeekDateEnd)
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
    @transactionItem.created_at = DateTime.now
    @transactionItem.updated_at = DateTime.now
    @transaction.transactionItems << @transactionItem
    if @transactionItem.save
      {:transaction_item=>@transactionItem,:status=>"success",:method=>"add"}.to_json
    else
      {:transaction_item=>@transactionItem,:status=>"failure"}.to_json
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
    @transaction_item.updated_at = DateTime.now

    if @transaction_item.save
      {:transaction_item=>@transaction_item,:status=>"success"}.to_json
    else
      {:status=>"failure"}.to_json
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
  @transaction.transaction_date = DateTime.parse(params[:transaction_date])
  @transaction.created_at = DateTime.now
  @transaction.updated_at = DateTime.now

  if @transaction.save
    {:transaction=>@transaction,:status=>"success"}.to_json
  else
    {:ttransaction=>@transaction,:status=>"failure"}.to_json
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
        {:ttransaction=>@transaction,:status=>"failure"}.to_json
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

get '/test' do

  # @transactionItem = TransactionItem.new
  # @transactionItem.description = "tesst 36"
  # @transactionItem.grand_total = 54
  # @transactionItem.discount_total = 0.00
  # @transactionItem.tax_total = 0.00
  # @transactionItem.created_at = DateTime.now
  # @transactionItem.updated_at = DateTime.now
  # @transaction.transactionItems << @transactionItem
  # @transactionItem.save

  #@transaction.to_json
end
