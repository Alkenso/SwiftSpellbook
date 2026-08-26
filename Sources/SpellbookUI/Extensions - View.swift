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

private struct ValuedView<T, Body: View>: View {
    let value: T
    let body: Body
}

extension View {
    public func retaining<T>(_ value: T) -> some View {
        ValuedView(value: value, body: self)
    }
}

extension View {
    public func sync<Observable: ValueObserving>(
        _ value: Binding<Observable.ObservedValue>,
        from observable: Observable
    ) -> some View where Observable.ObservedValue: Equatable {
        retaining(observable.observe(includingCurrentValue: true) { newValue in
            newValue.flatMap { value.wrappedValue = $0 }
        })
    }
    
    public func sync<T: Sendable, Observable: ValueObserving>(
        _ value: Binding<T>,
        from observable: Observable
    ) -> some View where Observable.ObservedValue == ValueChange<T> {
        retaining(observable.observe(includingCurrentValue: true) { newValue in
            newValue.flatMap { value.wrappedValue = $0.new }
        })
    }
    
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func sync<T: Equatable & Sendable>(_ value: Binding<T>, with store: ValueStore<T>) -> some View {
        self
            .onChange(of: value.wrappedValue) { store.update($0) }
            .retaining(store.observe(includingCurrentValue: true) { $0.flatMap { value.wrappedValue = $0.new } })
    }
}

//extension View {
//    @inlinable
//    public nonisolated func onAppear(delay: TimeInterval, perform action: @escaping @MainActor () -> Void) -> some View {
//        onAppear {
//            DispatchQueue.main.asyncAfter(delay: delay, execute: action)
//        }
//    }
//}
//
//
//extension View {
//    func clipContour<S: Shape>(_ shape: S, contourWidth: CGFloat) -> some View {
//        clipShape(shape).clipShape(shape.stroke(lineWidth: contourWidth))
//    }
//    
//    func frame(offset: CGPoint, size: CGSize?) -> some View {
//        self
//            .offset(x: offset.x, y: offset.y)
//            .frame(width: size?.width, height: size?.height)
//    }
//    
//    func trackingSize(_ body: @escaping (CGSize) -> Void) -> some View {
//        background {
//            GeometryReader { geo in Color.clear.onChange(of: geo.size, initial: true) { body(geo.size) } }
//                .ignoresSafeArea()
//        }
//    }
//    
//    func trackingSize(_ value: Binding<CGSize?>) -> some View {
//        trackingSize { value.wrappedValue = $0 }
//    }
//}
//
//
//
//extension Text {
//    init(systemImage: String) {
//        self.init(Image(systemName: systemImage))
//    }
//}
