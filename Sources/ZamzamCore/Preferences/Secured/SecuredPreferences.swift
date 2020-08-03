//
//  SecuredPreferences.swift
//  ZamzamCore
//
//  Created by Basem Emara on 2020-03-07.
//  Copyright © 2020 Zamzam Inc. All rights reserved.
//

/// A thin wrapper to manage Keychain, or other services that conform to `SecuredPreferencesService`.
///
///     let keychain = SecuredPreferences(
///         service: SecuredPreferencesKeychainService()
///     )
///
///     keychain.set("kjn989hi", forKey: .token)
///     keychain.get(.token) // "kjn989hi"
///
///     // Define strongly-typed keys
///     extension SecuredPreferencesAPI.Key {
///         static let token = SecuredPreferencesAPI.Key("token")
///     }
///
public struct SecuredPreferences {
    private let service: SecuredPreferencesService
    
    public init(service: SecuredPreferencesService) {
        self.service = service
    }
}

public extension SecuredPreferences {
    
    /// Retrieves the value from keychain that corresponds to the given key.
    ///
    /// Accessing the underlying Keychain storage is an expensive operation.
    /// Use a background thread when possible, then store within memory for future retrievals.
    ///
    /// - Parameter key: The key that is used to read the user defaults item.
    func get(_ key: SecuredPreferencesAPI.Key) -> String? {
        service.get(key)
    }
}

public extension SecuredPreferences {
    
    /// Stores the value in the keychain item under the given key.
    ///
    /// - Parameters:
    ///   - value: Value to be written to the keychain.
    ///   - key: Key under which the value is stored in the keychain.
    @discardableResult
    func set(_ value: String?, forKey key: SecuredPreferencesAPI.Key) -> Bool {
        let result = service.set(value, forKey: key)
        
        guard #available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *) else { return result }
        Self.subject.send(key.name)
        
        return result
    }
}

public extension SecuredPreferences {
    
    /// Deletes the single keychain item specified by the key.
    ///
    /// - Parameter key: The key that is used to delete the keychain item.
    /// - Returns: True if the item was successfully deleted.
    @discardableResult
    func remove(_ key: SecuredPreferencesAPI.Key) -> Bool {
        let result = service.remove(key)
        
        guard #available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *) else { return result }
        Self.subject.send(key.name)
        
        return result
    }
}

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension SecuredPreferences {
    private static let subject = PassthroughSubject<String, Never>()
    
    /// Returns a publisher that emits events when broadcasting secured preference changes.
    func publisher() -> AnyPublisher<String, Never> {
        Self.subject.eraseToAnyPublisher()
    }
}
#endif
