// Generated by CoffeeScript 1.7.1
(function() {
  $(function() {
    var chart, render_vis;
    chart = null;
    render_vis = function(csv) {
      $("#toolbar").css("visibility", "visible");
      $(".load-screen").hide();
      return chart = new BubbleChart(csv);
    };
    $("#file-uploader").on('change', (function(_this) {
      return function(e) {
        var file, fileReader;
        file = e.target.files[0];
        if (file.type === 'text/csv') {
          fileReader = new FileReader();
          fileReader.onload = function(e) {
            return render_vis(d3.csv.parse(fileReader.result));
          };
          return fileReader.readAsText(file);
        }
      };
    })(this));
    $("#nfl-dataset").on('click', (function(_this) {
      return function(e) {
        return d3.csv("data/football/players_2.csv", render_vis);
      };
    })(this));
    $("#billionaire-dataset").on('click', (function(_this) {
      return function(e) {
        return d3.csv("data/billion/billionaire.csv", render_vis);
      };
    })(this));
    return $("#auto-dataset").on('click', (function(_this) {
      return function(e) {
        return d3.csv("data/auto/auto.csv", render_vis);
      };
    })(this));
  });

}).call(this);
