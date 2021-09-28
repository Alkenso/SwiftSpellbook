//
//  File.swift
//  
//
//  Created by Alkenso (Vladimir Vashurkin) on 28.09.2021.
//

import Foundation


// MARK: - Comparable

extension Comparable {
    public func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
