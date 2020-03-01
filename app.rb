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
# before %r{/login} do
#   if !session[:username].nil?
#     redirect '/'
#   end
# end

before %r{.+\.json} do
    content_type 'application/json'
end

##############################################
### LOGIN INFORMATION
#############################################

Dir.glob('./controllers/*.rb').each { |file| require_relative file }


use LoginController
use AccountController
use TransactionController
use TransactionItemController
use DateController
use GoalController

####################################################
### LOGIN INFORMATION
###################################################






get '/getdate' do
	{:date=>DateTime.now}.to_json
end
