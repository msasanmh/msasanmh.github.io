jQuery.githubUserRepositories = function(username, callback) {  jQuery.getJSON("https://api.github.com/users/" + username + "/repos?callback=?", callback);} jQuery.fn.loadRepositores = function(username) {  this.html("<span>Querying GitHub for repositories...</span>");   var target = this;   $.githubUserRepositories(username, function(data) {    var repos = data.data;    sortByNumberOfWatchers(repos);     var list = $('<dl/>');    target.empty().append(list);    $(repos).each(function() {      list.append('<dt><a href="'+ this.url +'">' + this.name + '</a></dt>');      list.append('<dd>' + this.description + '</dd>');    });  });   function sortByNumberOfWatchers(repos) {    repos.sort(function(a,b) {      return b.watchers - a.watchers;    });  }};







