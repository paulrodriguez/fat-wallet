require_relative '../helpers/validate_login'

class AccountController < Sinatra::Base
  register Sinatra::Flash
  helpers ViewTypeDate,CurrentWeek,CurrentMonth, ValidateLogin

  set :views, File.expand_path('../../views', __FILE__)

  before do
    if is_user_logged_in() == FALSE
      redirect '/login'
    end
  end

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
end
