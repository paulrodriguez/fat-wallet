require_relative '../helpers/validate_login'
class TransactionController < Sinatra::Base
  helpers ViewTypeDate,CurrentWeek,CurrentMonth, ValidateLogin

  before do
    if is_user_logged_in() == FALSE
      redirect '/login'
    end
  end

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
end


class TransactionItemController < Sinatra::Base
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
end
