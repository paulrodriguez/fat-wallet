// transaction item equivalent to backend
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
};

// the transaction view model that stores transaction array and operations for individual transaction
function TransactionViewModel() {
    var t = this;
    t.transactions = new ko.observableArray([]);
    // fields to add new transaction
    t.newTransactionDescription = ko.observable();
    t.newTransactionGrandTotal = ko.observable();
    t.newTransactionDiscountTotal = ko.observable("0.00");
    t.newTransactionTaxTotal = ko.observable("0.00");
    t.newTransactionDate = ko.observable();

    $.getJSON("/transactions.json", function(raw) {
        var transactions = $.map(raw.transactions, function(item) { return new Transaction(item) });
        t.transactions(transactions);
    });


    t.combinedTotal = ko.pureComputed({
      owner: t,
      read: function() {
        var total = 0;
        for(var p =0; p < this.transactions().length; p++) {
          // skip any destroyed items in observable array
          if(this.transactions()[p]._destroy!==undefined && this.transactions()[p]._destroy==true) {continue;}
          total += this.transactions()[p].grand_total();
        }
        return total;
      },
      deferEvaluation: true
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
        //console.log(ko.toJS(newTransaction));

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
  };

  // initialize ko.
  ko.applyBindings(new TransactionViewModel());
