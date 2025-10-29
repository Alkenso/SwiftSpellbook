//  MIT License
//
//  Copyright (c) 2023 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

public protocol SBUnit: RawRepresentable, Sendable {}

extension SBUnit {
    /// Perform conversion between measurement units.
    /// - Parameters:
    ///     - value: Unit magnitude.
    ///     - from: `value` measurement units. `nil` means base units.
    ///     - to: `resulting` measurement units. `nil` means base units.
    public static func convert(
        _ value: Double, _ from: Self? = nil, to: Self? = nil
    ) -> Double where RawValue: BinaryFloatingPoint {
        convert(value, from.flatMap { Double($0.rawValue) }, to: to.flatMap { Double($0.rawValue) })
    }
    
    /// Perform conversion between measurement units.
    /// - Parameters:
    ///     - value: Unit magnitude.
    ///     - from: `value` measurement units. `nil` means base units.
    ///     - to: `resulting` measurement units. `nil` means base units.
    public static func convert(
        _ value: Double, _ from: Self? = nil, to: Self? = nil
    ) -> Double where RawValue: BinaryInteger {
        convert(value, from.flatMap { Double($0.rawValue) }, to: to.flatMap { Double($0.rawValue) })
    }
    
    private static func convert(_ value: Double, _ from: Double?, to: Double?) -> Double {
        value * (from ?? 1.0) / (to ?? 1.0)
    }
}

public struct SBUnitInformationStorage: SBUnit {
    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    public static let kilobyte = Self(rawValue: 1024)
    public static let megabyte = Self(rawValue: 1024 * kilobyte.rawValue)
    public static let gigabyte = Self(rawValue: 1024 * megabyte.rawValue)
}

public struct SBUnitTime: SBUnit {
    public var rawValue: TimeInterval
    public init(rawValue: TimeInterval) { self.rawValue = rawValue }
    
    public static let minute = Self(rawValue: 60)
    public static let hour = Self(rawValue: 60 * minute.rawValue)
    public static let day = Self(rawValue: 24 * hour.rawValue)
}
