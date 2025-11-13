//
//  Item.swift
//  AICalorieEstimator
//
//  Created by 薛宜安 on 2025/11/13.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
