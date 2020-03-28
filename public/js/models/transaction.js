// transaction model
class Transaction(data) {
  this.id = ko.observable(data.id);

  this.description = ko.observable(data.description);

  // cost totals information
  this.grand_total    = ko.observable(Number.parseFloat(data.grand_total));
  this.tax_total      = ko.observable(Number.parseFloat(data.tax_total));
  this.discount_total = ko.observable(Number.parseFloat(data.discount_total));
  this.tax_rate       = ko.observable(Number.parseFloat(data.tax_rate));
  // date information
  var transaction_date = convertDateToString(data.transaction_date);
  this.transaction_date = ko.observable(transaction_date);
  this.created_at       = ko.observable(data.created_at);
  this.updated_at       = ko.observable(data.updated_at);

  // items for the transaction
  this.transaction_items = ko.observableArray(data.transaction_items);

  // fields for each individual transaction to add items to it.
  this.tiDescription = ko.observable();
  this.tiQuantity = ko.observable(1);
  this.tiGrandTotal = ko.observable("0.00");
  this.tiDiscountTotal = ko.observable("0.00");
  this.tiTaxTotal = ko.observable("0.00");

  this.toggle_transaction_items = ko.observable(false);
};
