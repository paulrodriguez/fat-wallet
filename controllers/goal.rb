class GoalController < Sinatra::Base
  helpers ViewTypeDate,CurrentWeek,CurrentMonth, ValidateLogin

  before do
    if is_user_logged_in() == FALSE
      redirect '/login'
    end
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
end
