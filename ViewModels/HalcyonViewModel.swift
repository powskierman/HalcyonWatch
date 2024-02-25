import Foundation
import Combine
import HassWatchFramework

class HalcyonViewModel: ObservableObject {
    
    @Published var deviceState: HalcyonDeviceState?
    @Published var errorMessage: String?
    @Published var temperature: Double = 20 // Default temperature
    @Published var mode: HvacModes = .heat // Default temperature
    static let shared = HalcyonViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    private let service = HalcyonAPIService.shared
    private var isUpdating: Bool = false
    private var lastRequestID: String?
    
    init() {
        $temperature
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newTemperature in
                guard let self = self else { return }
                self.sendTemperatureUpdate(entityId: "climate.halcyon_Chambre", temperature: Int(newTemperature), mode: self.mode) { success in
                    DispatchQueue.main.async {
                        if success {
                            // Handle success, e.g., update UI or state as necessary
                            print("Temperature update was successful.")
                        } else {
                            // Handle failure, e.g., show error message
                            print("Failed to update temperature.")
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchDeviceState(for deviceId: String) {
        service.fetchDeviceState(deviceId: deviceId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] state in
                self?.deviceState = state
            })
            .store(in: &self.cancellables)
    }
    
    func sendCommand(entityId: String, hvacMode: HvacModes, temperature: Int) {
        service.sendCommand(entityId: entityId, hvacMode: hvacMode, temperature: temperature)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { _ in
                // Handle success if needed, maybe update some state
            })
            .store(in: &self.cancellables)
    }
    
    // Function to update temperature and optionally HVAC mode in Home Assistant
    func sendTemperatureUpdate(entityId: String, temperature: Int, mode: HvacModes, completion: @escaping (Bool) -> Void) {
        // Construct your request payload
        let payload: [String: Any] = [
            "entity_id": entityId,
            "temperature": temperature,
            "hvac_mode": mode.rawValue
        ]
        
        // Convert payload to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            completion(false)
            return
        }
        
        // Perform the network request
        let endpoint = "api/services/climate/set_temperature"
        service.sendCommand(entityId: entityId, hvacMode: mode, temperature: temperature)
            .sink(receiveCompletion: { completionStatus in
                switch completionStatus {
                case .finished:
                    // Request completed successfully
                    completion(true)
                case .failure(_):
                    // Request failed
                    completion(false)
                }
            }, receiveValue: { _ in
                // Here, you might handle the response data if necessary
            })
            .store(in: &cancellables) // Assuming you have a cancellables set to manage the lifetime of your subscriptions
    }
}
    
    
//    func sendTemperatureUpdate(entityId: String, temperature: Int, mode: HvacModes) {
//         let requestID = "\(entityId)-\(temperature)-\(mode.rawValue)-\(Date().timeIntervalSince1970)"
//         guard requestID != lastRequestID else { return }
//         lastRequestID = requestID
//        isUpdating = true
//        print("Updating temperature to \(temperature) and mode to \(mode) for \(entityId)")
//        service.sendCommand(entityId: entityId, hvacMode: mode, temperature: temperature)
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { [weak self] completion in
//                switch completion {
//                case .finished:
//                    print("Command to set temperature and mode sent successfully for \(entityId)")
//                case .failure(let error):
//                    self?.errorMessage = "Failed to set temperature and mode for \(entityId): \(error.localizedDescription)"
//                    print("Failed to set temperature and mode for \(entityId): \(error)")
//                }
//            }, receiveValue: { _ in
//                // No value to receive since sendCommand returns Void on success
//            })
//            .store(in: &cancellables)
//        isUpdating = false
//    }
//}
