//
//  RGBColor.swift
//  SwiftSpellbook
//
//  Created by Alkenso (Vladimir Vashurkin) on 2025-01-30.
//

import SpellbookFoundation

import SwiftUI

extension View {
    @ViewBuilder
    public func modify<Content: View>(@ViewBuilder _ transform: (Self) -> Content?) -> some View {
        if let content = transform(self) {
            content
        } else {
            self
        }
    }
}
