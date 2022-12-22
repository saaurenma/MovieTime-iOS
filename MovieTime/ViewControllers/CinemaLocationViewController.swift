//
//  BookTicketsViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 4/5/2022.
//

import UIKit
import MapKit

/// Defines a View Controller where the user can view the directions to the cinema selected
class CinemaLocationViewController: UIViewController, MKMapViewDelegate {
    
    // MapView and label outlets
    @IBOutlet weak var cinemaMapView: MKMapView!
    @IBOutlet weak var cinemaLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    var currentLocation: CLLocation?
    
    let geocoder = CLGeocoder()
    var cinemaLocations: [MKMapItem] = []
    var currentAddress: String?
    var currentCinema: String?
    var cinemaLocationItem: MKMapItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cinemaLocations = []
        
        
        cinemaMapView.delegate = self
        cinemaMapView.showsUserLocation = true
        
        // get the cinema and address from previous view controller
        getCinemaDirections(stringAddress: currentAddress!)
        if let currentCinema = currentCinema,let currentAddress = currentAddress {
            cinemaLabel.text = currentCinema
            addressLabel.text = currentAddress
        }
        
    }
    
    /// Gets directions to cinema from the current location
    func getCinemaDirections(stringAddress: String) {
        geocoder.geocodeAddressString(stringAddress) { [self] (placemarks, error) in
            
            // if cinema location cannot be found based on address exit function
            guard let placemarks = placemarks, let cinemaLocation = placemarks.first?.location else {
                return
            }
            
             // Set current location coordinates and placemarks
            let currentLocationCoordinate = currentLocation?.coordinate
            let currentLocationPlacemark = MKPlacemark(coordinate: currentLocationCoordinate!)
            
            // Set cinema location coordinates and placemarks
            let cinemaLocationCoordinate = cinemaLocation.coordinate
            let cinemaLocationPlacemark = MKPlacemark(coordinate: cinemaLocationCoordinate)
            
            // Plot an annotation of the cinema on the map
            let annotation = MKPointAnnotation()
            annotation.coordinate = cinemaLocationCoordinate
            if let currentAddress = currentAddress, let currentCinema = currentCinema {
                // Prepare cinema annotation
                annotation.title = currentCinema
                annotation.subtitle = currentAddress
            }
            // Add the annotation to mapview
            cinemaMapView.addAnnotation(annotation)
            cinemaMapView.selectAnnotation(cinemaMapView.annotations[0], animated: true)

            
            let currentLocationItem = MKMapItem(placemark: currentLocationPlacemark)
            cinemaLocationItem = MKMapItem(placemark: cinemaLocationPlacemark)
            
            // create a directions request from current location to cinema location
            let directionsRequest = MKDirections.Request()
            directionsRequest.source = currentLocationItem
            directionsRequest.destination = cinemaLocationItem
            directionsRequest.transportType = .automobile
            directionsRequest.requestsAlternateRoutes = true
            
            let directions = MKDirections(request: directionsRequest)
            directions.calculate {(response, error) in
                
                guard let response = response else {
                    print("Error")
                    return
                }
                
                // take the first route provided
                let pathTaken = response.routes[0]
                // add the polyline to the mapview
                cinemaMapView.addOverlay(pathTaken.polyline)
                cinemaMapView.setVisibleMapRect(pathTaken.polyline.boundingMapRect, animated: true)
            }
            
            
        }
        
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let mapPolyline = overlay as? MKPolyline {
            // Properties of the line drawn from the current location to the cinema
                let polyLineRenderer = MKPolylineRenderer(polyline: mapPolyline)
                polyLineRenderer.strokeColor = .systemBlue
                polyLineRenderer.lineWidth = 4.0
                return polyLineRenderer
            }
        return MKOverlayRenderer()
    }
    

    
    /// Allows the user to open the directions in apple maps
    @IBAction func openInAppleMaps(_ sender: Any) {
        let alertController = UIAlertController(title: "Open in Apple Maps", message: "Are you sure you would like to open these directions in Apple Maps?", preferredStyle: .alert)
        
        // Give the user the option not to go to Apple Maps.
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [self] action in
            let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
            if let currentCinema = currentCinema {
                cinemaLocationItem?.name = currentCinema
                cinemaLocationItem?.openInMaps(launchOptions: launchOptions)
            }

        }))
        
        alertController.addAction(UIAlertAction(title: "No", style: .default))
        present(alertController, animated: true)
    }
    
    

}
