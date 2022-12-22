//
//  CinemaTypeCollectionReusableView.swift
//  MovieTime
//
//  Created by Saauren Mankad on 7/6/2022.
//

import UIKit

/// Custom CollectionReusableView to define a section header contained in the label defined as  showingTypeLabel for the CollectionView appearing in the ShowtimeTableViewCell.
class CinemaTypeCollectionReusableView: UICollectionReusableView {
    /// Outlet to the label displaying the showing type.
    @IBOutlet weak var showingTypeLabel: UILabel!
    
}
    
