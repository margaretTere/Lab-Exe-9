import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startNavigationButton: UIButton!

    var locations: [CLLocationCoordinate2D] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        let ontarioCenter = CLLocationCoordinate2D(latitude: 43.65, longitude: -79.38)
        let region = MKCoordinateRegion(
            center: ontarioCenter,
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
        mapView.setRegion(region, animated: true)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        startNavigationButton?.isEnabled = false
    }

    @objc func handleMapTap(_ sender: UITapGestureRecognizer) {
        let locationInView = sender.location(in: mapView)
        let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)

        
        if let index = locations.firstIndex(where: { $0.isClose(to: coordinate, threshold: 100) }) {
            locations.remove(at: index)
            updateMap()
            return
        }

      
        if locations.count < 3 {
            locations.append(coordinate)
        } else {
            locations.removeFirst()
            locations.append(coordinate)
        }

  
        let labels = ["A", "B", "C"]
        mapView.removeAnnotations(mapView.annotations)
        for (i, loc) in locations.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = loc
            annotation.title = labels[i]
            mapView.addAnnotation(annotation)
        }

        updateMap()

       
        startNavigationButton?.isEnabled = (locations.count == 3)
    }

    func updateMap() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        let labels = ["A", "B", "C"]

        for (index, loc) in locations.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = loc
            annotation.title = labels[index]  
            mapView.addAnnotation(annotation)
        }

        if locations.count == 3 {
            drawTriangle()
            addDistanceLabels()
        }
    }


    func drawTriangle() {
        mapView.removeOverlays(mapView.overlays)

        let polyline = MKPolyline(coordinates: locations, count: 3)
        mapView.addOverlay(polyline)

        let polygon = MKPolygon(coordinates: locations, count: 3)
        mapView.addOverlay(polygon)
    }

    func addDistanceLabels() {
        for i in 0..<3 {
            let start = locations[i]
            let end = locations[(i + 1) % 3]

            let distance = start.distance(to: end)

            let midPoint = CLLocationCoordinate2D(
                latitude: (start.latitude + end.latitude) / 2,
                longitude: (start.longitude + end.longitude) / 2
            )

            let annotation = MKPointAnnotation()
            annotation.coordinate = midPoint
            annotation.title = String(format: "%.2f km", distance / 1000)
            mapView.addAnnotation(annotation)
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .green
            renderer.lineWidth = 3
            return renderer
        } else if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    
    
    @IBAction func startNavigation(_ sender: Any) {
        guard locations.count == 3 else {
            print("Not enough locations for navigation")
            return
        }

        let start = MKMapItem(placemark: MKPlacemark(coordinate: locations[0])) // A
        let stop1 = MKMapItem(placemark: MKPlacemark(coordinate: locations[1])) // B
        let stop2 = MKMapItem(placemark: MKPlacemark(coordinate: locations[2])) // C
        let end = MKMapItem(placemark: MKPlacemark(coordinate: locations[0])) // Return to A

        let mapItems = [start, stop1, stop2, end]

        let options: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
      
        MKMapItem.openMaps(with: mapItems, launchOptions: options)
    }
    


}


extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let start = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let end = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return start.distance(from: end)
    }

    func isClose(to coordinate: CLLocationCoordinate2D, threshold: CLLocationDistance) -> Bool {
        return self.distance(to: coordinate) < threshold
    }
}

