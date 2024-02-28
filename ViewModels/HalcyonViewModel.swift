import Foundation
import Combine
import HassWatchFramework

class HalcyonViewModel: ObservableObject {
    static let shared = HalcyonViewModel(restClient: .shared)
    
    private var restClient: HassRestClient
    private var cancellables = Set<AnyCancellable>()
    
    // Observable properties with default values
    @Published var currentEntityId: String = ""
    @Published var tempSet: Int = 22
    @Published var fanSpeed: String = "auto"
    @Published var halcyonMode: HvacModes = .cool
    @Published var errorMessage: String?
    @Published var lastCallStatus: CallStatus = .pending
    @Published var hasErrorOccurred: Bool = false
    
    // Timer for debouncing temperature updates
    private var updateTimer: Timer?
    private let debounceInterval: TimeInterval = 0.5
    
    init(restClient: HassRestClient) {
        self.restClient = restClient
    }
    
    // Function to cycle to the next HVAC mode and send an update to Home Assistant
    public func nextHvacMode() {
        halcyonMode = halcyonMode.next
        sendTemperatureUpdate(entityId: currentEntityId, mode: halcyonMode, temperature: tempSet)
    }
    
    // Function to update temperature and optionally HVAC mode in Home Assistant
    func sendTemperatureUpdate(entityId: String, mode: HvacModes, temperature: Int) {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            self.restClient.changeState(entityId: entityId, newState: temperature) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let entity):
                        print("Temperature and mode set successfully for \(entityId): \(entity.state)")
                    case .failure(let error):
                        print("Failed to set temperature and mode for \(entityId): \(error)")
                        self.errorMessage = "Failed to set temperature and mode for \(entityId): \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    func fetchInitialState() {
        fetchState(for: "climate.halcyon_chambre")
    }

    public func fetchState(for entityId: String) {
        restClient.fetchState(entityId: entityId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entity):
                    if let attributes = entity.thermostatAttributes() {
                        self?.processThermostatAttributes(attributes)
                    } else {
                        self?.errorMessage = "Failed to decode thermostat attributes"
                    }
                case .failure(let error):
                    self?.errorMessage = "Error fetching initial state: \(error.localizedDescription)"
                }
            }
        }
    }

    private func processThermostatAttributes(_ attributes: ThermostatAttributes) {
        // Update your ViewModel properties based on the fetched attributes
        self.tempSet = Int(attributes.currentTemperature ?? 22)
        self.halcyonMode = HvacModes(rawValue: attributes.hvacMode ?? "cool") ?? .off
    }
}
