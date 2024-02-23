// This service is responsible for performing network requests to fetch or send data to Home Assistant via HassFramework

import Foundation
import Combine
import HassWatchFramework

class HalcyonAPIService: ObservableObject {
    static let shared = HalcyonAPIService()
    private var restClient: HassRestClient

    init() {
        self.restClient = HassRestClient.shared
    }

    func sendCommand(entityId: String, hvacMode: HvacModes, temperature: Int) -> AnyPublisher<HAEntity, Error> {
        let payload: [String: Any] = [
            "entity_id": entityId,
            "temperature": temperature,
            "hvac_mode": hvacMode.rawValue
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return Fail(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"])).eraseToAnyPublisher()
        }

        let correctEndpoint = "api/services/climate/set_temperature"
        return HassRestClient.shared.performRequest(endpoint: correctEndpoint, method: "POST", body: jsonData)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode else {
                    throw URLError(.badServerResponse)
                }
                return output.data
            }
            .decode(type: HAEntity.self, decoder: JSONDecoder())
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func fetchDeviceState(deviceId: String) -> AnyPublisher<HassRestClient.DeviceState, Error> {
        return restClient.fetchDeviceState(deviceId: deviceId)
    }
}
