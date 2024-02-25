//
//  HalcyonDevice.swift
//  HalcyonWatch Watch App
//
//  Created by Michel Lapointe on 2024-02-23.
//

struct HalcyonDeviceState: Codable {
    let entityId: String
    let state: String
    let attributes: Attributes
    let lastChanged: String
    let lastUpdated: String
    let context: DeviceContext

    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state, attributes
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
        case context
    }

    struct Attributes: Codable {
        let hvacModes: [String]
        let minTemp: Double
        let maxTemp: Double
        let targetTempStep: Double
        let fanModes: [String]
        let swingModes: [String]
        let currentTemperature: Double
        let temperature: Double
        let fanMode: String
        let swingMode: String
        let friendlyName: String
        let supportedFeatures: Int

        enum CodingKeys: String, CodingKey {
            case hvacModes = "hvac_modes"
            case minTemp = "min_temp"
            case maxTemp = "max_temp"
            case targetTempStep = "target_temp_step"
            case fanModes = "fan_modes"
            case swingModes = "swing_modes"
            case currentTemperature = "current_temperature"
            case temperature, fanMode = "fan_mode"
            case swingMode = "swing_mode"
            case friendlyName = "friendly_name"
            case supportedFeatures = "supported_features"
        }
    }

    struct DeviceContext: Codable {
        let id: String
        let parentId: String?
        let userId: String?

        enum CodingKeys: String, CodingKey {
            case id
            case parentId = "parent_id"
            case userId = "user_id"
        }
    }
}
