//
//  UNUserNotificationCenter.swift
//  ZamzamKit
//
//  Created by Basem Emara on 2/3/17.
//  Copyright © 2017 Zamzam. All rights reserved.
//

import UserNotifications
import CoreLocation

public extension UNUserNotificationCenter {
    static let mainCategoryIdentifier = "mainCategory"
    
    /// Registers your app’s notification types and the custom actions that they support.
    ///
    /// - Parameters:
    ///   - category: The category identifier.
    ///   - actions: The actions for the category.
    ///   - authorizations: The authorization options.
    func register(
        delegate: UNUserNotificationCenterDelegate? = nil,
        category: String = UNUserNotificationCenter.mainCategoryIdentifier,
        actions: [UNNotificationAction]? = nil,
        authorizations: UNAuthorizationOptions? = [.alert, .badge, .sound],
        completion: ((Bool) -> Void)? = nil)
    {
        register(delegate: delegate, categories: [category: actions], authorizations: authorizations, completion: completion)
    }
    
    /// Registers your app’s notification types and the custom actions that they support.
    ///
    /// - Parameters:
    ///   - category: The category identifier.
    ///   - actions: The actions for the category.
    ///   - authorizations: The authorization options.
    ///   - completion: The callback to process with the granted flag provided.
    func register(
        delegate: UNUserNotificationCenterDelegate? = nil,
        categories: [String: [UNNotificationAction]?],
        authorizations: UNAuthorizationOptions? = [.alert, .badge, .sound],
        completion: ((Bool) -> Void)? = nil)
    {
        self.delegate ?= delegate
    
        getNotificationSettings { settings in
            let categorySet = Set(categories.map {
                UNNotificationCategory(
                    identifier: $0.key,
                    actions: $0.value ?? [],
                    intentIdentifiers: [],
                    options: .customDismissAction
                )
            })
            
            guard let authorizations = authorizations, settings.authorizationStatus == .notDetermined else {
                // Register category if applicable
                return self.getNotificationCategories {
                    defer {
                        let granted = settings.authorizationStatus == .authorized
                        DispatchQueue.main.async { completion?(granted) }
                    }
                    
                    guard categorySet != $0 else { return }
                    self.setNotificationCategories(categorySet)
                }
            }
            
            // Request permission before registering if applicable
            self.requestAuthorization(options: authorizations) { granted, error in
                defer { DispatchQueue.main.async { completion?(granted) } }
                guard granted else { return }
                self.setNotificationCategories(categorySet)
            }
        }
    }
}

public extension UNUserNotificationCenter {
    
    /// Returns a list of all all pending or delivered user notifications.
    func getNotificationRequests(completion: @escaping ([UNNotificationRequest]) -> Void) {
        var notificationRequests = [UNNotificationRequest]()
        let taskGroup = DispatchGroup()
        
        taskGroup.enter()
        getPendingNotificationRequests {
            notificationRequests.append(contentsOf: $0)
            taskGroup.leave()
        }
        
        taskGroup.enter()
        getDeliveredNotifications {
            notificationRequests.append(contentsOf: $0.map { $0.request })
            taskGroup.leave()
        }
        
        taskGroup.notify(queue: .main) {
            completion(notificationRequests)
        }
    }
    
    /// Retrieve the pending notification request.
    ///
    /// - Parameters:
    ///   - withIdentifier: The identifier for the requests.
    ///   - completion: The completion block that will return the request with the identifier.
    func get(withIdentifier: String, completion: @escaping (UNNotificationRequest?) -> Void) {
        getNotificationRequests {
            let requests = $0.first { $0.identifier == withIdentifier }
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    /// Retrieve the pending notification requests.
    ///
    /// - Parameters:
    ///   - withIdentifiers: The identifiers for the requests.
    ///   - completion: The completion block that will return the requests with the identifiers.
    func get(withIdentifiers: [String], completion: @escaping ([UNNotificationRequest]) -> Void) {
        getNotificationRequests {
            let requests = $0.filter { withIdentifiers.contains($0.identifier) }
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    /// Determines if the pending notification request exists.
    ///
    /// - Parameters:
    ///   - withIdentifier: The identifier for the requests.
    ///   - completion: The completion block that will return the request with the identifier.
    func exists(withIdentifier: String, completion: @escaping (Bool) -> Void) {
        get(withIdentifier: withIdentifier) { completion($0 != nil) }
    }
}

public extension UNUserNotificationCenter {

    /// Schedules a local notification for delivery.
    ///
    /// - Parameters:
    ///   - timeInterval: The time interval of when to fire the notification.
    func add(
        body: String,
        title: String? = nil,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound? = .default,
        attachments: [UNNotificationAttachment]? = nil,
        timeInterval: TimeInterval = 0,
        repeats: Bool = false,
        identifier: String = UUID().uuidString,
        category: String = UNUserNotificationCenter.mainCategoryIdentifier,
        userInfo: [String: Any]? = nil,
        completion: ((Error?) -> Void)? = nil)
    {
        // Constuct content
        let content = UNMutableNotificationContent().with {
            $0.body = body
            $0.categoryIdentifier = category
        
            // Assign optional values to content
            $0.title ?= title
            $0.subtitle ?= subtitle
            $0.badge ?= badge
            $0.sound = sound
            if let userInfo = userInfo { $0.userInfo = userInfo }
            if let attachments = attachments, !attachments.isEmpty { $0.attachments = attachments }
        }
    
        // Construct request with trigger
        let trigger = timeInterval > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats) : nil
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
        add(request, withCompletionHandler: completion)
    }
    
    /// Schedules a local notification for delivery.
    ///
    /// - Parameters:
    ///   - date: The date of when to fire the notification.
    func add(
        date: Date,
        body: String,
        title: String? = nil,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound? = .default,
        attachments: [UNNotificationAttachment]? = nil,
        repeats: ScheduleInterval = .once,
        calendar: Calendar = .current,
        identifier: String = UUID().uuidString,
        category: String = UNUserNotificationCenter.mainCategoryIdentifier,
        userInfo: [String: Any]? = nil,
        completion: ((Error?) -> Void)? = nil)
    {
        // Constuct content
        let content = UNMutableNotificationContent().with {
            $0.body = body
            $0.categoryIdentifier = category
        
            // Assign optional values to content
            $0.title ?= title
            $0.subtitle ?= subtitle
            $0.badge ?= badge
            $0.sound = sound
            if let userInfo = userInfo { $0.userInfo = userInfo }
            if let attachments = attachments, !attachments.isEmpty { $0.attachments = attachments }
        }
    
        // Constuct date components for trigger
        // https://github.com/d7laungani/DLLocalNotifications/blob/master/DLLocalNotifications/DLLocalNotifications.swift#L31
        let components: DateComponents
        switch repeats {
        case .once: components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        case .minute: components = calendar.dateComponents([.second], from: date)
        case .hour: components = calendar.dateComponents([.minute], from: date)
        case .day: components = calendar.dateComponents([.hour, .minute], from: date)
        case .week: components = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        case .month: components = calendar.dateComponents([.hour, .minute, .day], from: date)
        case .year: components = calendar.dateComponents([.hour, .minute, .day, .month], from: date)
        }
    
        // Construct request with trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats != .once)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
        add(request, withCompletionHandler: completion)
    }
    
    #if os(iOS)
    /// Schedules a local notification for delivery.
    ///
    /// - Parameters:
    ///   - region: The region of when to fire the notification.
    func add(
        region: CLRegion,
        body: String,
        title: String? = nil,
        subtitle: String? = nil,
        badge: NSNumber? = nil,
        sound: UNNotificationSound? = .default,
        attachments: [UNNotificationAttachment]? = nil,
        repeats: Bool = false,
        identifier: String = UUID().uuidString,
        category: String = UNUserNotificationCenter.mainCategoryIdentifier,
        userInfo: [String: Any]? = nil,
        completion: ((Error?) -> Void)? = nil)
    {
        // Constuct content
        let content = UNMutableNotificationContent().with {
            $0.body = body
            $0.categoryIdentifier = category
        
            // Assign optional values to content
            $0.title ?= title
            $0.subtitle ?= subtitle
            $0.badge ?= badge
            $0.sound = sound
            if let userInfo = userInfo { $0.userInfo = userInfo }
            if let attachments = attachments, !attachments.isEmpty { $0.attachments = attachments }
        }
    
        // Construct request with trigger
        let trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    
        add(request, withCompletionHandler: completion)
    }
    #endif
}

public extension UNUserNotificationCenter {
    
    /// Remove pending or delivered user notifications.
    ///
    /// - Parameter withIdentifier: The identifier of the user notification to remove.
    func remove(withIdentifier id: String) {
        remove(withIdentifiers: [id])
    }
    
    /// Remove pending and delivered user notifications.
    ///
    /// - Parameter withIdentifiers: The identifiers of the user notifications to remove.
    func remove(withIdentifiers ids: [String]) {
        guard !ids.isEmpty else { return }
        removePendingNotificationRequests(withIdentifiers: ids)
        removeDeliveredNotifications(withIdentifiers: ids)
    }
    
    /// Remove pending or delivered user notifications.
    ///
    /// - Parameter withCategory: The category of the user notification to remove.
    func remove(withCategory category: String, completion: (() -> Void)? = nil) {
        remove(withCategories: [category], completion: completion)
    }
    
    /// Remove pending or delivered user notifications.
    ///
    /// - Parameter withCategory: The categories of the user notification to remove.
    func remove(withCategories categories: [String], completion: (() -> Void)? = nil) {
        getNotificationRequests {
            self.remove(
                withIdentifiers: $0.compactMap {
                    categories.contains($0.content.categoryIdentifier) ? $0.identifier : nil
                }
            )
            
            completion?()
        }
    }
    
    /// Remove all pending or delivered user notifications.
    func removeAll() {
        removeAllPendingNotificationRequests()
        removeAllDeliveredNotifications()
    }
}
