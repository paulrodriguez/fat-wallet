require_relative '../helpers/validate_login'

class DateController < Sinatra::Base
  helpers CurrentWeek,CurrentMonth,ViewTypeDate, ValidateLogin

  before do
    if is_user_logged_in() == FALSE
      redirect '/login'
    end
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

  get '/date_range.json' do
    # TODO: set up custom date ranges

  end
end
