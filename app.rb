require 'sinatra'
require 'sinatra/flash'
#require 'sinatra/base'
require 'data_mapper'
require File.dirname(__FILE__)+'/models.rb'
require 'json'

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
	erb :index

end

get '/transactions.json' do
	@transactions = Transaction.all
	@transactions.to_json
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
