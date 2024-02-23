import Foundation
import Combine
import HassWatchFramework

class HalcyonViewModel: ObservableObject {
    
    @Published var deviceState: HassRestClient.DeviceState?
    @Published var errorMessage: String?
    static let shared = HalcyonViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    private let service = HalcyonAPIService.shared

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
        func sendTemperatureUpdate(entityId: String, mode: HvacModes, temperature: Int) {
            // Assuming you have a method in HalcyonAPIService to send commands
            service.sendCommand(entityId: entityId, hvacMode: mode, temperature: temperature)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        // Handle completion, such as confirming the command was sent
                        print("Command to set temperature and mode sent successfully for \(entityId)")
                    case .failure(let error):
                        // Update the ViewModel state to reflect the error
                        self?.errorMessage = "Failed to set temperature and mode for \(entityId): \(error.localizedDescription)"
                        print("Failed to set temperature and mode for \(entityId): \(error)")
                    }
                }, receiveValue: { _ in
                    // No value to receive since sendCommand returns Void on success
                    // You could update a state variable here to indicate success if needed
                })
                .store(in: &cancellables)
        }
    }

