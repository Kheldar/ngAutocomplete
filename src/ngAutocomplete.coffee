"use strict"

###*
A directive for adding google places autocomplete to a text box
google places autocomplete info: https://developers.google.com/maps/documentation/javascript/places

Usage:

<input type="text"  ng-autocomplete ng-model="autocomplete" options="options" details="details"/>

+ ng-model - autocomplete textbox value

+ details - more detailed autocomplete result, includes address parts, latlng, etc. (Optional)

+ options - configuration for the autocomplete (Optional)

+ types: type,        String, values can be 'geocode', 'establishment', '(regions)', or '(cities)'
+ bounds: bounds,     Google maps LatLngBounds Object, biases results to bounds, but may return results outside these bounds
+ country: country    String, ISO 3166-1 Alpha-2 compatible country code. examples; 'ca', 'us', 'gb'
+ watchEnter:         Boolean, true; on Enter select top autocomplete result. false(default); enter ends autocomplete

example:

options = {
types: '(cities)',
country: 'ca'
}
###
angular.module("ngAutocomplete", []).directive "ngAutocomplete", ->
  require: "ngModel"
  scope:
    ngModel: "="
    options: "=?"
    details: "=?"

  link: (scope, element, attrs, controller) ->
    
    #options for autocomplete
    watchEnter = false
    scope.gPlace = new google.maps.places.Autocomplete(element[0], {})
    google.maps.event.addListener scope.gPlace, "place_changed", ->
      result = scope.gPlace.getPlace()
      if result isnt `undefined`
        if result.address_components isnt `undefined`
          scope.$apply ->
            scope.details = result
            controller.$setViewValue element.val()
            return

        else
          if watchEnter
            getPlace result
            element[0].blur()
      return

    
    #function to get retrieve the autocompletes first result using the AutocompleteService 
    getPlace = (result) ->
      autocompleteService = new google.maps.places.AutocompleteService()
      if result.name.length > 0
        autocompleteService.getPlacePredictions
          input: result.name
          offset: result.name.length
        , listentoresult = (list, status) ->
          if not list? or list.length is 0
            scope.$apply ->
              scope.details = null
              return

          else
            placesService = new google.maps.places.PlacesService(element[0])
            placesService.getDetails
              reference: list[0].reference
            , detailsresult = (detailsResult, placesServiceStatus) ->
              if placesServiceStatus is google.maps.GeocoderStatus.OK
                scope.$apply ->
                  controller.$setViewValue detailsResult.formatted_address
                  element.val detailsResult.formatted_address
                  scope.details = detailsResult
                  
                  #on focusout the value reverts, need to set it again.
                  watchFocusOut = element.on("blur", (event) ->
                    element.val detailsResult.formatted_address
                    element.unbind "blur"
                    return
                  )
                  return

              return

          return

      return

    controller.$render = ->
      location = controller.$viewValue
      element.val location
      return

    
    #watch options provided to directive
    scope.watchOptions = ->
      scope.options

    scope.$watch scope.watchOptions, (->
      if scope.options
        watchEnter = scope.options.watchEnter
        if scope.options.types
          scope.gPlace.setTypes [scope.options.types]
        else
          scope.gPlace.setTypes []
        if scope.options.bounds
          scope.gPlace.setBounds scope.options.bounds
        else
          scope.gPlace.setBounds null
        if scope.options.country
          scope.gPlace.setComponentRestrictions country: scope.options.country
        else
          scope.gPlace.setComponentRestrictions null
      return
    ), true
    return

