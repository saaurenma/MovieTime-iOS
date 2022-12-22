//
//  ShowtimeTableViewCell.swift
//  MovieTime
//
//  Created by Saauren Mankad on 6/6/2022.
//

import UIKit
import EventKit
import EventKitUI

/// Custom TableViewCell class to define the properties of each cell in the TableViewController named ShowtimesTableViewController
class ShowtimeTableViewCell: UITableViewCell, EKEventEditViewDelegate {
    
    
    
    @IBOutlet weak var cinemaNameLabel: UILabel!
    @IBOutlet weak var showtimeCollectionView: UICollectionView!
    
    var showings: [ShowingData]? {
        didSet {
            showtimeCollectionView.reloadData()
        }
    }
    
    var currentTheatre: String?
    var currentTheatreAddress: String?
    var currentMovieTitle: String?
    var currentMovieRuntime: Int?
    var currentMovieShowtimeDate: String?
    
    
    let eventStore = EKEventStore()
    
    var showtimeParentViewController: ShowtimesTableViewController?
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set the delegate and data source for the CollectionView as the current class.
        showtimeCollectionView.delegate = self
        showtimeCollectionView.dataSource = self
        
        // Add rounded corners to the CollectionView.
        showtimeCollectionView.layer.cornerRadius = 4
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}


extension ShowtimeTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    /// Tells the collectionView how many items (CollectionView cells) should be in each section. In this case, it will be the number of times for each type of showing offered by the theatre.
    /// - Parameters:
    ///   - collectionView: The collection view requesting this information.
    ///   - section: An index number identifying a section in collectionView. In this case it refers to the index of the cinema type.
    /// - Returns: The count of the number of times for a given type of cinema from the showings array.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showings![section].time!.count
    }
    
    /// Tells the collectionView the number of sections to display.
    /// - Parameter collectionView: The collection view requesting this information.
    /// - Returns: The number of sections in collectionView. In this case, it will be the number of showing types offered by the cinema (e.g. just Standard or others such as Deluxe).
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return showings!.count
    }
    
    
    
    /// Sets the label of the section header which defines the type of showing.
    /// - Parameters:
    ///   - collectionView: The collection view requesting this information.
    ///   - kind: The kind of supplementary view to provide. The value of this string is defined by the layout object that supports the supplementary view.
    ///   - indexPath: The index path that specifies the location of the new supplementary view.
    /// - Returns: A CollectionReusableView of type CinemaTypeCollectionReusableView with it's properties set.
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "cinemaTypeHeader", for: indexPath) as? CinemaTypeCollectionReusableView {
            
            // Set the label in the section header as the showingType. A showing type is not provided, set it to Standard as default.
            if let showingType = showings?[indexPath.section].type {
                sectionHeader.showingTypeLabel.text = showingType
            }
            else {
                sectionHeader.showingTypeLabel.text = "Standard"
            }
            return sectionHeader
        }
        
        return UICollectionReusableView()
    }
    
    /// Defines the proprties of each cell in the CollectionView. Each cell is casted to ShowtimeCollectionViewCell to enable this.
    /// - Parameters:
    ///   - collectionView: The collectionView requesting this information.
    ///   - indexPath: The index path that specifies the location of the item (cell).
    /// - Returns: A CollectionView cell of type ShowtimeCollectionViewCell with all the relevant properties set.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // cast the cell to ShowtimeCollectionViewCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "timeAndTypeCell", for: indexPath) as! ShowtimeCollectionViewCell
        
        // set label text value as the time for the showing type.
        cell.timeLabel.text = showings?[indexPath.section].time?[indexPath.row]
        
        // set cosmetic properties of cell
        cell.layer.borderColor = UIColor.systemGray6.cgColor
        cell.layer.borderWidth = 5
        cell.layer.cornerRadius = 12
        
        
        cell.layer.backgroundColor = UIColor(named: "collectionViewColour")?.cgColor
        
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var dateAndTimeString: String?
        
        let currentYear = Calendar.current.component(.year, from: Date()).description
        
        // create date and time string
        if let dateString = currentMovieShowtimeDate, let selectedTime =  showings?[indexPath.section].time?[indexPath.row] {
            dateAndTimeString = dateString + " \(currentYear) " + selectedTime
            
        }
        
        // convert the date and time string to a date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "MMMM d yyy h:mma"
        var startTimeAndDate = dateFormatter.date(from: dateAndTimeString!)
        
        if startTimeAndDate == nil {
            dateFormatter.dateFormat = "MMMM d yyy HH:mm"
            startTimeAndDate = dateFormatter.date(from: dateAndTimeString!)
        }
        
        if startTimeAndDate == nil {
            dateFormatter.dateFormat = "d MMMM yyy HH:mm"
            startTimeAndDate = dateFormatter.date(from: dateAndTimeString!)
        }
        
        if startTimeAndDate == nil {
            dateFormatter.dateFormat = "d MMMM yyy HH:mma"
            startTimeAndDate = dateFormatter.date(from: dateAndTimeString!)
        }
        
        var endTimeAndDate: Date
        
        // If the movie has a runtime then calculate the end time, else assume it is 90 minutes long
        if let currentMovieRuntime = currentMovieRuntime {
            endTimeAndDate = Calendar.current.date(byAdding: .minute, value: currentMovieRuntime, to: startTimeAndDate!)!
        }
        else {
            endTimeAndDate = Calendar.current.date(byAdding: .minute, value: 90, to: startTimeAndDate!)!
        }
        
        

        
        let actionSheet = UIAlertController(title: "Select Option", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Add as event", style: .default, handler: { [self] action in
            
            // Request access to the user's Apple calendar events
            eventStore.requestAccess( to: EKEntityType.event, completion:{(granted, error) in

                DispatchQueue.main.async { [self] in

                    // Create an event for the user to add
                    if (granted) && (error == nil) {
                        let event = EKEvent(eventStore: self.eventStore)
                        if let currentMovieTitle = currentMovieTitle, let currentTheatre = currentTheatre {
                            event.title = "\(currentMovieTitle) @ \(currentTheatre)"
                        }

                        event.startDate = startTimeAndDate
                        event.endDate = endTimeAndDate
                        event.location = currentTheatreAddress
                        let eventController = EKEventEditViewController()
                        eventController.event = event
                        eventController.eventStore = self.eventStore
                        eventController.editViewDelegate = self
                        // show the event controller so the user can modify it and add it to their calendar
                        showtimeParentViewController!.present(eventController, animated: true, completion: nil)
                    }
                }
            })
            
        }))
        
        if let currentTheatreAddress = currentTheatreAddress {
            // set variables and perform segue to show the cinema location
            actionSheet.addAction(UIAlertAction(title: "View directions to cinema", style: .default, handler: { [self] action in
                showtimeParentViewController?.selectedAddress = currentTheatreAddress
                showtimeParentViewController?.selectedCinema = currentTheatre
                showtimeParentViewController?.performSegue(withIdentifier: "showCinemaLocation", sender: nil)
            }))
            
        }
        

        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        showtimeParentViewController!.present(actionSheet, animated: true)

    }
    
    
    
    
}

