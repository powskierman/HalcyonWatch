//
//  HalcyonModels.swift
//  HalcyonWatch Watch App
//
//  Created by Michel Lapointe on 2024-02-25.
//

import SwiftUI
import HassWatchFramework

// Define a struct for ClimateDeviceAttributes specific to the needs of HalcyonWatch

extension AnyCodable {
    func valueAsDouble() -> Double? {
        return value as? Double
    }

    func valueAsString() -> String? {
        return value as? String
    }
}

extension HAEntity {
    func thermostatAttributes() -> ThermostatAttributes? {
        guard let hvacMode = self.attributes.additionalAttributes["hvac_mode"]?.valueAsString(),
              let currentTemperature = self.attributes.additionalAttributes["current_temperature"]?.valueAsDouble(),
              let targetTemperature = self.attributes.additionalAttributes["target_temperature"]?.valueAsDouble() else {
            return nil
        }
        
        return ThermostatAttributes(from: self.attributes)
    }
}

extension HAAttributes {
    func value(for key: String) -> AnyCodable? {
        self.additionalAttributes[key]
    }
}
struct ThermostatAttributes {
    var hvacMode: String?
    var currentTemperature: Double?
    var targetTemperature: Double?

    init(from haAttributes: HAAttributes) {
        self.hvacMode = haAttributes.value(for: "hvac_mode")?.valueAsString()
        self.currentTemperature = haAttributes.value(for: "current_temperature")?.valueAsDouble()
        self.targetTemperature = haAttributes.value(for: "temperature")?.valueAsDouble()
    }
}
