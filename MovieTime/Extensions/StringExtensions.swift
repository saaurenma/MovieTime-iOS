//
//  StringExtensions.swift
//  MovieTime
//
//  Created by Saauren Mankad on 9/6/2022.
//

import Foundation

extension String: LocalizedError {
    
    public var errorDescription: String? { return self }
    
}
