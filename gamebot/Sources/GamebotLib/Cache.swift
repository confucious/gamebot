//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/27/19.
//

import Foundation
import DynamoDB
import SlackModels

enum CacheError: Error {
    case dynamoDbGet(String, Error)
    case dynamoDbSet(String, Error)
    case utf8EncodingError(String, String)
}
class Cache {

    private enum Name {
        static let keyName = "key"
        static let valueName = "value"
    }

    private static func db() -> DynamoDB {
        return DynamoDB(region: .useast1)
    }

    private static var _tableName: String?

    private static func tableName() -> String {
        if let tableName = _tableName {
            return tableName
        }

        let tableName = ProcessInfo.processInfo.environment["cache_table"] ?? "gamebot-cache"
        _tableName = tableName
        return tableName
    }

    static func get<T: Codable>(from key: String) throws -> T? {
        do {
            let getItem = DynamoDB.Get(
                key: [
                    Name.keyName: .init(s: key)
                ],
                tableName: tableName())
            let result = try db().transactGetItems(.init(transactItems: [.init(get: getItem)]))
                .wait()
            guard let json = result.responses?.first?.item?[Name.valueName]?.s else {
                return nil
            }
            guard let jsonData = json.data(using: .utf8) else {
                throw CacheError.utf8EncodingError(key, json)
            }
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            throw CacheError.dynamoDbGet(key, error)
        }
    }

    static func set<T: Codable>(_ value: T, into key: String) throws {
        do {
            let jsonData = try JSONEncoder().encode(value)
            let json = String(data: jsonData, encoding: .utf8)
            let setItem = DynamoDB.TransactWriteItem(
                put: .init(
                    item: [
                        Name.keyName: .init(s: key),
                        Name.valueName: .init(s: json),
                    ],
                    tableName: tableName()))
            _ = try db().transactWriteItems(.init(transactItems: [setItem]))
                .wait()
        } catch {
            throw CacheError.dynamoDbSet(key, error)
        }
    }
}
