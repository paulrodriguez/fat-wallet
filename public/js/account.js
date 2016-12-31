function AccountViewModel() {
    var self = this;
    self.onSubmit = function(data)
    {
      //console.log($(data).serialize());

      var json_data = $(data).serialize();

      $.post("/account.json", json_data, function(response) // sends 'post' request
        {
            // on success callback
            console.log(response)
        })
    }
}

ko.applyBindings(new AccountViewModel());
