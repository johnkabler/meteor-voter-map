window.markers = []

createMarkers = -> 
  markers = new L.MarkerClusterGroup()
  Libraries.find().forEach (library) ->
    lat = library.lat
    lng = library.lng
    popup = "#{library.name}<br>#{library.address}<br>#{library.city}<br>#{library.postcode}<br>#{library.phone}"
    blueMarker = L.AwesomeMarkers.icon
      icon: 'star',
      prefix: 'fa'
    markers.addLayer(new L.marker([lat,lng], {icon: blueMarker}).bindPopup(popup))
  Voters.find().forEach (voter) ->
    lat = voter.latitude
    lng = voter.longitude
    popup = "#{voter.tweet}<br>#{voter.query}<br>#{voter.party_affiliation}<br>#{voter.birth_date}"
    redMarker = L.AwesomeMarkers.icon
      icon: 'star'
      prefix: 'fa'
      markerColor: 'red'
    greenMarker = L.AwesomeMarkers.icon 
      icon: 'star'
      prefix: 'fa'
      markerColor: 'green'
    blueMarker = L.AwesomeMarkers.icon
      icon: 'star',
      prefix: 'fa'
    if voter.party_affiliation == "REP"
          markers.addLayer(new L.marker([lat,lng],{icon: redMarker}).bindPopup(popup))
    else if voter.party_affiliation == "DEM"
          markers.addLayer(new L.marker([lat,lng], {icon: blueMarker}).bindPopup(popup))
    else
          markers.addLayer(new L.marker([lat,lng], {icon: greenMarker}).bindPopup(popup))

  window.map.addLayer(markers)
  window.markers.push(markers)
  # turn off spinner - loaded
  window.map.spin(false)


@Cities = new Meteor.Collection('cities')
Meteor.subscribe('cities')

@Libraries = new Meteor.Collection('libraries')
Meteor.subscribe('libraries', createMarkers)

@Voters = new Meteor.Collection('voters')
Meteor.subscribe('voters', createMarkers)


Template.search_city.rendered = ->
  AutoCompletion.init("input#searchBox")

Template.search_city.events
  'keyup input#searchBox': ->
    AutoCompletion.autocomplete
      element: 'input#searchBox'
      collection: Cities
      field: 'city'
      limit: 0
      sort: { city: 1 }
  'click #search_button': ->
    # if pulling from dropdown then exact match
    input_value = $("input#searchBox").val()
    regex = "^" + input_value + "$"
    matches = Libraries.find({ city: { $regex : regex, $options:"i" }})
    input_value = regex if matches.count() > 0
    libraries = Libraries.find({city: { $regex : input_value, $options:"i" }})
    # clear marker groups
    for marker in window.markers
      window.map.removeLayer(marker)
    # clear all markers
    layers = window.map._layers
    for key, val of layers
      window.map.removeLayer(val) if val._latlng
    # add markers based on search
    libraries.forEach (library) ->
      lat = library.lat
      lng = library.lng
      popup = "#{library.name}<br>#{library.address}<br>#{library.city}<br>#{library.postcode}<br>#{library.phone}"
      blueMarker = L.AwesomeMarkers.icon
        icon: 'star',
        prefix: 'fa'
      L.marker([lat,lng], {icon: blueMarker}).addTo(window.map).bindPopup(popup)
  'click #reset_button': ->
    # clear all markers
    layers = window.map._layers
    for key, val of layers
      window.map.removeLayer(val) if val._latlng
    $("#searchBox").val('')
    markers = new L.MarkerClusterGroup()
    Libraries.find().forEach (library) ->
      lat = library.lat
      lng = library.lng
      popup = "#{library.name}<br>#{library.address}<br>#{library.city}<br>#{library.postcode}<br>#{library.phone}"
      blueMarker = L.AwesomeMarkers.icon
        icon: 'star',
        prefix: 'fa'
      markers.addLayer(new L.marker([lat,lng], {icon: blueMarker}).bindPopup(popup))
    window.map.addLayer(markers)
    window.markers.push(markers)

# resize the layout
window.resize = (t) ->
  w = window.innerWidth
  h = window.innerHeight
  top = 190
  c = w - 40
  m = (h-top) - 20
  t.find('#container').style.width = "#{c}px"
  t.find('#map').style.height = "#{m}px" 

# Need to adapt this into coffeescript and then
# use it to make the map update in real time

# Template.map.created = function() {
#   Parties.find({}).observe({
#     added: function(party) {
#       var marker = new L.Marker(party.latlng, {
#         _id: party._id,
#         icon: createIcon(party)
#       }).on('click', function(e) {
#         Session.set("selected", e.target.options._id);
#       });      
#       addMarker(marker);
#     },
#     changed: function(party) {
#       var marker = markers[party._id];
#       if (marker) marker.setIcon(createIcon(party));
#     },
#     removed: function(party) {
#       removeMarker(party._id);
#     }
#   });
# }

Template.map.rendered = ->  
  # resize on load
  window.resize(@)

  # resize on resize of window
  $(window).resize =>
    window.resize(@)

  # create default image path
  L.Icon.Default.imagePath = 'packages/leaflet/images'

  congress_layer = L.geoJson(null,
  style:
    color: "#DE0404"
    weight: 2
    opacity: 0.4
    fillOpacity: 0.1
  )
  nielsen_layer = L.geoJson(null,
    style:
      color: "#0e4378"
      weight: 2
      opacity: 0.4
      fillOpacity: 0.1
  )
  county_layer = L.geoJson(null,
    style:
      color: "#FCEC00"
      weight: 2
      opacity: 0.4
      fillOpacity: 0.1
  )
  # create a map in the map div, set the view to a given place and zoom
  window.map = L.map 'map', 
    doubleClickZoom: false
  .setView([27.8781136, -83.22677956445312], 6)

  # add a CloudMade tile layer with style #997
  # L.tileLayer.provider 'CloudMade', 
  #   apiKey: 'c337a7e5e7c241958df4332a8713a0a9',
  #   styleID: '997'
  #   attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, 
  #   <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © 
  #   <a href="http://cloudmade.com">CloudMade</a>, Dataset updated 2012-01-11, Created by
  #   <a href="http://www.bevanhunt.com">Bevan Hunt
  #   <br> This information is provided by the 
  #   <a href="http://www2.gov.bc.ca/">Province of British Columbia</a> under the 
  #   <a href="http://www.data.gov.bc.ca/dbc/admin/terms.page">Open Government License for Government of BC Information v.BC1.0</a>'
  # .addTo(window.map)
  overlayMaps =
    "Congressional Districts": congress_layer
    "Media Markets": nielsen_layer
    "Counties": county_layer

  congress_geojson = topojson.feature(congress, congress.objects.districts)
  
  congress_layer.addData(congress_geojson)

  nielsen_geojson = topojson.feature(nielsen, nielsen.objects.nielsen_dma)

  nielsen_layer.addData(nielsen_geojson)

  counties_geojson = topojson.feature(uscounties, uscounties.objects.counties)

  county_layer.addData(counties_geojson)


    

  # $.getJSON "nielsentopo.json", (data) ->
  #   nielsen_geojson = topojson.feature(data, data.objects.nielsen_dma)
  #   nielsen_layer.addData(nielsen_geojson)
  #   return

  # $.getJSON "us.json", (data) ->
  #   county_geojson = topojson.feature(data, data.objects.counties)
  #   county_layer.addData(county_geojson)
  #   return

  L.tileLayer('http://{s}.tile.stamen.com/toner-lite/{z}/{x}/{y}.png', {opacity: .9}).addTo(window.map);
  #window.map.addLayer(congress_layer)
  # add locate me
  L.control.locate().addTo(window.map)
  L.control.layers(null, overlayMaps).addTo(window.map)

  # loading spinner
  window.map.spin(true)