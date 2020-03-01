class LoginController < Sinatra::Base
  register Sinatra::Flash
  set :views, File.expand_path('../../views', __FILE__)
  # if already logged in, then redirect to index page
  before %r{/login} do
    if !session[:username].nil?
      redirect '/'
    end
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
end
