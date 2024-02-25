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
    
    func sendCommand(entityId: String, hvacMode: HvacModes, temperature: Int) -> AnyPublisher<Void, Error> {
        let payload: [String: Any] = [
            "entity_id": entityId,
            "temperature": temperature,
            "hvac_mode": hvacMode.rawValue
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return Fail(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"])).eraseToAnyPublisher()
        }
        
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "Invalid JSON"
        print("Sending JSON payload: \(jsonString)")
        
        let correctEndpoint = "api/services/climate/set_temperature"
        print("Request URL: \(correctEndpoint)")
        
        return HassRestClient.shared.performRequest(endpoint: correctEndpoint, method: "POST", body: jsonData)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode else {
                    throw URLError(.badServerResponse)
                }
                print("HTTP Response Status Code: \(httpResponse.statusCode)")
                return ()
            }
            .mapError { error in
                print("Network request error: \(error)")
                return error
            }
            .eraseToAnyPublisher()
    }


    
func fetchDeviceState(deviceId: String) -> AnyPublisher<HalcyonDeviceState, Error> {
    restClient.fetchDeviceState(deviceId: deviceId)
        .tryMap { data -> Data in
            // Log the raw JSON string for debugging
            if let json = String(data: data, encoding: .utf8) {
                print("Raw JSON data: \(json)")
            }
            return data
        }
        .decode(type: HalcyonDeviceState.self, decoder: JSONDecoder())
        .mapError { error -> Error in
            // Log decoding errors
            print("Decoding error: \(error)")
            return error
        }
        .eraseToAnyPublisher()
    }
}
