class BubbleChart
  constructor: (data) ->
    @data = data
    @width = 1350
    @height = 800

    @tooltip = CustomTooltip("player_tooltip")

    @vis = d3.select("#vis").append("svg")
       .attr("viewBox", "0 0 #{@width} #{@height}")
#      .attr("width", @width)
#      .attr("height", @height)

    @force = d3.layout.force()
      .gravity(-0.01)
      .charge((d) -> -Math.pow(d.radius, 2.0) * 1.5)
      .size([@width, @height])

    # this is necessary so graph and model stay in sync
    # http://stackoverflow.com/questions/9539294/adding-new-nodes-to-force-directed-layout
    @nodes = @force.nodes()

    @curr_filters = []
    this.create_filters()

    this.split_buttons()

  create_filters: () =>
    @filter_names = []
    i = 1
    $.each @data[0], (d) =>
      if d != 'id' && d != 'name'
        @filter_names.push {value: d, color: 'color-' + i }
        i += 1

    filters = []

    # populate the filters from the dataset
    @data.forEach (d) =>
      $.each d, (k, v) =>
        if k != 'id' && k != 'name'
          filter_obj = {filter: k, value: v}
          filter_exists = $.grep filters, (e) =>
            return e.filter == k && e.value == v
          if filter_exists.length == 0
            filters.push(filter_obj)

    # add the filters to the select
    d3.select("#filter-select").selectAll('option').data(filters).enter()
      .append("option")
      # unfortunately value is the only thing passed to select2
      # so we have to hack together this string param
      .attr("value", (d) => d.filter + ":" + d.value)
      .text((d) -> d.value)

    # create the actual select2 obj and add a change listener
    $("#filter-select").select2({
      placeholder: 'Type here to get started',
      width: '300px',
      dropdownCssClass: "customdrop"
    }).on("change", (e) =>
      if typeof e.added != 'undefined'
        if typeof e.added.id != 'undefined'
          val = e.added.id.split(':')
          this.add_nodes(val[0], val[1])
          this.add_filter(val[0], val[1])
    )

  add_filter: (field, val) =>
    @curr_filters.push({filter: field, value: val})

    # until I can figure out how to get the id based on the val
    rand = String(Math.random()).substring(2,12)
    $("#filter-select-buttons").append("<button id='"+rand+"'>"+val+"</button>")

    button = $("#"+rand)
    button.on("click", (e) =>
      this.remove_nodes(field, val)
      button.detach()
    )
    button_color = $.grep(@filter_names, (e) => e.value == field)[0].color
    button.addClass(button_color)

  add_nodes: (field, val) =>
    @data.forEach (d) =>
      if d[field] == val
        if $.grep(@nodes, (e) => e.id == d.id).length == 0 # if it doesn't already exist in nodes

          vals = {} # create a hash with the appropriate filters
          $.each @filter_names, (k, f) =>
            vals[f.value] = d[f.value]

          node = {
            id: d.id
            radius: 8
            name: d.name
            values: vals
            color: d.team
            x: Math.random() * 900
            y: Math.random() * 800
            tarx: @width/2.0
            tary: @height/2.0
          }
          @nodes.push node
    this.update()

  remove_nodes: (field, val) =>
    # remove this filter from the @curr_filters
    @curr_filters = $.grep @curr_filters, (e) =>
      return e['filter'] != field && e['value'] != val

    # this was the only array iterator + removal I could get to work
    len = @nodes.length
    while (len--)
      if @nodes[len]['values'][field] == val # node with offending value found
        # now check that it doesnt have other values that would allow it to stay
        should_remove = true
        @curr_filters.forEach (k) =>
          if @nodes[len]['values'][k['filter']] == k['value']
            should_remove = false
        # we can now remove it
        if should_remove == true
          @nodes.splice(len, 1)

    this.update()

  split_buttons: () =>
    d3.select("#split-buttons").selectAll('button').data(@filter_names).enter()
      .append("button")
      .text((d) -> d.value)
      .attr("class", (d) -> d.color)
      .on("click", (d) => this.split_by(d.value))

  split_by: (split) =>
    curr_vals = []

    # first get number of unique values in the filter
    @circles.each (c) =>
      if curr_vals.indexOf(c['values'][split]) < 0
        curr_vals.push c['values'][split]

    # then determine what spots all the values should go to
    num_rows = Math.round(Math.sqrt(curr_vals.length)) + 1
    num_cols = curr_vals.length / (num_rows - 1)

    curr_row = 0
    curr_col = 0

    # padding because the clumps tend to float off the screen
    width_2 = @width - 250
    height_2 = @height - 130

    # remove any currently present split labels
    @vis.selectAll(".split-labels").remove()

    curr_vals.forEach (s, i) =>
      curr_vals[i] = { split: s, tarx: 50 + (0.5 + curr_col) * (width_2 / num_cols), tary: 70 + (0.5 + curr_row) * (height_2 / num_rows)}

      # now do the text labels
      @vis.append("text")
        .attr("x", curr_vals[i].tarx - 50)
        .attr("y", curr_vals[i].tary)
        .attr("class", 'split-labels')
        .text(s)

      curr_col++
      if curr_col >= num_cols
        curr_col = 0
        curr_row++

    # then update all circles tarx and tary appropriately
    @circles.each (c) =>
      curr_vals.forEach (s) =>
        if s.split == c['values'][split]
          c.tarx = s.tarx
          c.tary = s.tary

    # then update
    this.update()

  update: () =>
    @circles = @vis.selectAll("circle")
      .data(@nodes, (d) -> d.id)

    # create new circles as needed
    that = this
    @circles.enter().append("circle")
      .attr("r", 0)
      .attr("stroke-width", 3)
      .attr("id", (d) -> "bubble_#{d.id}")
      .attr("class", (d) -> d.color.toLowerCase().replace(/\s/g, '_').replace('.',''))
      .on("mouseover", (d,i) -> that.show_details(d,i,this))
      .on("mouseout", (d,i) -> that.hide_details(d,i,this))

    # Fancy transition to make bubbles appear to 'grow in'
    @circles.transition().duration(2000).attr("r", (d) -> d.radius)

    # this is IMPORTANT otherwise removing nodes won't work
    @circles.exit().remove()

    @force.on "tick", (e) =>
      @circles.each(this.move_towards_target(e.alpha))
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)

    @force.start()

  # move node towards the target defined in (tarx,tary)
  move_towards_target: (alpha) =>
    (d) =>
      d.x = d.x + (d.tarx - d.x) * (0.7) * alpha
      d.y = d.y + (d.tary - d.y) * (0.7) * alpha

  show_details: (data, i, element) =>
    content = "<div class='tooltip-name'>#{data.name}</div>"
    $.each data.values, (k, v) ->
      content +="#{v}<br/>"
    @tooltip.showTooltip(content,d3.event)

  hide_details: (data, i, element) =>
    @tooltip.hideTooltip()

  safe_string: (input) =>
    input.toLowerCase().replace(/\s/g, '_').replace('.','')

root = exports ? this

$ ->
  chart = null

  render_vis = (csv) ->
    chart = new BubbleChart csv

  d3.csv "data/players.csv", render_vis

  render_conf = (csv) ->
    conferences = []
    d3.csv.parseRows(csv).forEach (r) =>
      conferences.push { name: r[0], teams: r.slice(1) }
    d3.select("#school-select-wrapper").selectAll('button').data(conferences).enter()
      .append("button")
      .attr("value", (d) -> d.name)
      .text((d) -> d.name)
      .on("click", (d) -> $("#school-select").select2('val', d.teams, true))

  d3.text "data/conferences.csv", render_conf
