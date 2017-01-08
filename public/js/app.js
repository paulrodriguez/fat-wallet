/*ko.extenders.formatDate = function(target, option) {
    //create a writable computed observable to intercept writes to our observable
    var result = ko.pureComputed({
        read: function() {
          target("testing");
        }
    }).extend({ notify: 'always' });

    //initialize with current value to make sure it is rounded appropriately
    result(target());

    //return the new computed observable
    return result;
};*/


ko.bindingHandlers.formatDate = {
    init: function (element, valueAccessor, allBindingsAccessor) {
        var value = ko.unwrap(valueAccessor());
        var arr1 = value.split("T");
        if(arr1.length) {
          var arr2 = arr1[0].split("-");
          if(arr2.length==3) {
            value = arr2[1]+"/"+arr2[2]+"/"+arr2[0];
          }
        }
        $(element).text(value);
    }
};


// transaction item model
function TransactionItem(data) {
    this.id = ko.observable(data.id);
    this.transaction_id = ko.observable(data.transaction_id);

    this.description = ko.observable(data.description);

    this.grand_total = ko.observable(data.grand_total);
    this.discount_total = ko.observable(data.discount_total);
    this.tax_total = ko.observable(data.tax_total);

    this.created_at = ko.observable(data.created_at);
    this.updated_at = ko.observable(data.updated_at);
}

// transaction model
function Transaction(data) {
  this.id = ko.observable(data.id);

  this.description = ko.observable(data.description);

  // cost totals information
  this.grand_total    = ko.observable(Number.parseFloat(data.grand_total));
  this.tax_total      = ko.observable(Number.parseFloat(data.tax_total));
  this.discount_total = ko.observable(Number.parseFloat(data.discount_total));

  // date information
  this.transaction_date = ko.observable(data.transaction_date);
  this.created_at       = ko.observable(data.created_at);
  this.updated_at       = ko.observable(data.updated_at);

  // items for the transaction
  this.transaction_items = ko.observableArray(data.transaction_items);

  // fields for each individual transaction to add items to it.
  this.tiDescription = ko.observable();
  this.tiGrandTotal = ko.observable("0.00");
  this.tiDiscountTotal = ko.observable("0.00");
  this.tiTaxTotal = ko.observable("0.00");
};

function CurrentWeek() {
  this.days_from_current_date = ko.observable(0);
  this.current_week_start = ko.observable();
  this.current_week_end = ko.observable();
  this.full_week = ko.observable();
}

function WeeklyGoal() {
  this.start_date = ko.observable();
  this.end_date = ko.observable();
  this.id = ko.observable();
  this.limit_amount = ko.observable(100.00);
}

// the transaction view model that stores transaction array and operations for individual transaction
function TransactionViewModel() {
    var t = this;
    t.transactions = new ko.observableArray([]);

    t.current_week = new CurrentWeek();
    // fields to add new transaction
    t.newTransactionDescription = ko.observable();
    t.newTransactionGrandTotal = ko.observable();
    t.newTransactionDiscountTotal = ko.observable("0.00");
    t.newTransactionTaxTotal = ko.observable("0.00");
    t.newTransactionDate = ko.observable();

    t.weeklyGoal = new WeeklyGoal();//ko.observable(100.00);

    // get transactions
    t.loadTransactions = function() {
      $.getJSON("/transactions.json", function(raw) {
          var transactions = $.map(raw.transactions, function(item) {
            item.transaction_items = Array();
            // build transaction items to add to transaction
            if(raw.transaction_items[item.id]!==undefined) {
              transaction_items_temp = $.map(raw.transaction_items[item.id],function(trans_item) {
                return new TransactionItem(trans_item);
              });

              item.transaction_items = transaction_items_temp;
            }// end if

            return new Transaction(item);
          }); // $.map

          t.transactions(transactions);
      }); // end $.getJSON
    };

    t.loadCurrentWeekInfo = function() {
      $.getJSON("/week_dates.json",function(raw){
        t.setCurrentWeek.call(t.current_week,raw);
      });
    };

    t.loadCurrentWeeklyGoal = function() {
        $.getJSON("/weekly_goals.json",function(raw){
          if(raw.weekly_goal!="undefined" && raw.status=="success") {
            /*t.weeklyGoal.limit_amount(raw.weekly_goal.limit_amount);
            t.weeklyGoal.start_date(raw.weekly_goal.start_date);
            t.weeklyGoal.end_date(raw.weekly_goal.end_date);
            t.weeklyGoal.id(raw.weekly_goal.id);*/
            t.setCurrentWeeklyGoal.call(t.weeklyGoal,raw.weekly_goal);
          } else {
            t.setCurrentWeeklyGoal.call(t.weeklyGoal,{limit_amount:100.00,start_date:"",end_date:"",id:null});
          }
        });
    };

    t.saveCurrentWeeklyGoal = function(data) {
      var id = ko.unwrap(data.id());
      if(id!==undefined || id!==null) {
        data._method = 'put';
      }
      //console.log(data);
      var jsonData = ko.toJS(data);
      $.ajax({
        url: "/weekly_goals.json",
        type: "POST",
        data: jsonData

      }).done(function(res){
        if(res.weekly_goal!==undefined) {
          t.setCurrentWeeklyGoal.call(t.weeklyGoal,res.weekly_goal);
          /*t.weeklyGoal.id(res.weekly_goal.user_id);
          t.weeklyGoal.limit_amount(res.weekly_goal.limit_amount);
          t.weeklyGoal.start_date(res.weekly_goal.start_date);
          t.weeklyGoal.end_date(res.weekly_goal.end_date);*/
        }
        if(res.errors!==undefined) {
          alert(res.errors.join("<br />"));
        }
      });
    }


    // load info for the first time
    t.loadTransactions();
    t.loadCurrentWeekInfo();
    t.loadCurrentWeeklyGoal();

    t.setCurrentWeek = function(data) {
      this.days_from_current_date(data.days_from_current_date);
      this.current_week_start(data.current_week_start);
      this.current_week_end(data.current_week_end);
      this.full_week(data.full_week);
    }

    t.getDifferentWeek = function(data) {
      $.ajax({
           url: "/week_dates.json",
           type: "POST",
           data: data
      }).done(function(res){
          t.setCurrentWeek.call(t.current_week,res);
          t.reloadTransactions();
          t.loadCurrentWeeklyGoal();
      });

    };

    t.reloadTransactions = function() {
      t.transactions.removeAll();
      t.loadTransactions();
    };

    //calculate combined total for each transaction
    t.combinedTotal = ko.pureComputed({
      owner: t,
      read: function() {
        var total = 0;
        for(var p =0; p < this.transactions().length; p++) {
          // skip any destroyed items in observable array
          if(this.transactions()[p]._destroy!==undefined && this.transactions()[p]._destroy==true) {continue;}
          total += this.transactions()[p].grand_total();
        }
        return Number.parseFloat(total).toFixed(2);
      },
      deferEvaluation: true
    });

    t.availableLimit = ko.pureComputed({
      owner: t,
      read: function() {
        return (this.weeklyGoal.limit_amount() - this.combinedTotal()).toFixed(2);
      }
    });

    // builds new transaction item from fields and sends ajax request to save into backend model
    t.addTransaction = function() {
        var newTransaction = new Transaction({
          description: this.newTransactionDescription(),
          grand_total: this.newTransactionGrandTotal(),
          tax_total: this.newTransactionDiscountTotal(),
          discount_total: this.newTransactionTaxTotal(),
          transaction_date: this.newTransactionDate()
        });

        t.transactions.push(newTransaction);
        t.saveTransaction(newTransaction);
        t.resetFormFields();
    };

    t.updateTransaction = function(transaction) {
        transaction._method = "put";
        t.saveTransaction(transaction);
        return true;
    };

    t.deleteTransaction = function(transaction) {
      transaction._method = "delete";
      t.transactions.destroy(transaction);
      t.saveTransaction(transaction);
    };

    t.resetFormFields = function() {
      this.newTransactionDescription("");
      this.newTransactionGrandTotal("");
      this.newTransactionDiscountTotal("");
      this.newTransactionTaxTotal("");
      this.newTransactionDate("");
    };
    t.setCurrentWeeklyGoal = function(data) {
      this.start_date(data.start_date);
      this.end_date(data.end_date);
      this.id(data.id);
      this.limit_amount(data.limit_amount);
    }

    t.saveTransaction = function(transaction) {
      var myData = ko.toJS(transaction);
      $.ajax({
           url: "/transactions.json",
           type: "POST",
           data: myData
      }).done(function(data){
          if(data.transaction!==undefined){
            transaction.id(data.transaction.id);
            transaction.transaction_date(data.transaction.transaction_date);
            transaction.created_at(data.transaction.created_at);
            transaction.updated_at(data.transaction.updated_at);
          }
      });
    };

    t.getTransactionItems = function(transaction) {
      $.getJSON("/transaction_items.json",{transaction_id: transaction.id}, function(raw) {
          //var transactions = $.map(raw.transactions, function(item) { return new Transaction(item) });
          //t.transactions(transactions);
      });
    };

    t.addTransactionItem = function(transaction) {
      // create new transaction item
      var newTransactionItem = new TransactionItem(
        {
          description: transaction.tiDescription,
          grand_total: transaction.tiGrandTotal,
          discount_total: transaction.discount_total,
          tax_total: transaction.tax_total,
          transaction_id: transaction.id
        }
      );
      t.saveTransactionItem(newTransactionItem,transaction);
      t.reserTransactionItemFields(transaction);
    };

    t.updateTransactionItem = function(transactionItem) {
      transactionItem._method = "put";
      t.saveTransactionItem(transactionItem);
      return true;
    };

    t.deleteTransactionItem = function(data) {
      data.transaction_item._method="delete";
      t.saveTransactionItem(data.transaction_item, data.transaction);
    };

    t.saveTransactionItem = function(transactionItem,transaction) {
      var jsonData = ko.toJS(transactionItem);
      $.ajax({
           url: "/transaction_items.json",
           type: "POST",
           data: jsonData
      }).done(function(data){
          // if successful in saving, update valuess
          if(data.transaction_item!==undefined && data.status=="success"){
            transactionItem.id(data.transaction_item.id);
            transactionItem.grand_total(data.transaction_item.grand_total);
            transactionItem.discount_total(data.transaction_item.discount_total);
            transactionItem.tax_total(data.transaction_item.tax_total);
            transactionItem.description(data.transaction_item.description);
            transactionItem.created_at(data.transaction_item.created_at);
            transactionItem.updated_at(data.transaction_item.updated_at);
            transactionItem.transaction_id(data.transaction_item.transaction_id);
          }
          // add to array of corresponding transaction
          if(data.method!==undefined) {
            if(data.method=="add") {
              transaction.transaction_items.push(transactionItem);
            } else if(data.method="delete") {
              transaction.transaction_items.destroy(transactionItem);
            }
          }


      });
    };

    t.reserTransactionItemFields = function(transaction) {
      transaction.tiDescription("");
      transaction.tiGrandTotal("0.00");
      transaction.tiDiscountTotal("0.00");
      transaction.tiTaxTotal("0.00");
    }
  };

  // initialize ko.
  ko.applyBindings(new TransactionViewModel());
