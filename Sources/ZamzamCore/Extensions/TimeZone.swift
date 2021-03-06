//
//  TimeZone.swift
//  ZamzamCore
//
//  Created by Basem Emara on 5/6/17.
//  Copyright © 2017 Zamzam Inc. All rights reserved.
//

import Foundation.NSTimeZone

public extension TimeZone {
    /// Unix representation of time zone usually used for normalizing.
    static let posix = TimeZone(identifier: "GMT")
}

public extension TimeZone {
    /// Determines if the time zone is the current time zone of the device.
    ///
    ///     let timeZone = TimeZone(identifier: "Europe/Paris")
    ///     timeZone?.isCurrent -> false
    var isCurrent: Bool { Self.current.secondsFromGMT() == secondsFromGMT() }

    /// The difference in seconds between the specified time zone and the current time zone of the device.
    ///
    ///     let timeZone = TimeZone(identifier: "Europe/Paris")
    ///     timeZone?.offsetFromCurrent -> -21600
    var offsetFromCurrent: Int { Self.current.secondsFromGMT() - secondsFromGMT() }
}
