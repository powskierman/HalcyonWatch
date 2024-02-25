//import SwiftUI
//
//struct ThermostatView: View {
//    @Binding var temperature: Double
//    @Binding var mode: HvacModes
//    var room: Room
//    @EnvironmentObject var climateService: HalcyonViewModel
//    
//    private let baseRingSize: CGFloat = 180
//    private let baseOuterDialSize: CGFloat = 170
//    private let minTemperature: CGFloat = 10
//    private let maxTemperature: CGFloat = 30
//    
//    private var ringSize: CGFloat { baseRingSize }
//    private var outerDialSize: CGFloat { baseOuterDialSize }
//    
//    var body: some View {
//        VStack {
//            GeometryReader { geometry in
//                ZStack {
//                    ThermometerScaleView()
//                        .frame(width: geometry.size.width, height: geometry.size.height)
//                    Circle()
//                        .trim(from: 0.25, to: min(CGFloat(temperature) / 40, 0.75))
//                        .stroke(
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color("Temperature Ring 1"), Color("Temperature Ring 2")]),
//                                startPoint: .top,
//                                endPoint: .bottom
//                            ),
//                            style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round)
//                        )
//                        .frame(width: ringSize, height: ringSize)
//                        .rotationEffect(.degrees(90))
//                        .animation(.linear(duration: 1), value: CGFloat(temperature) / 40)
//                    
//                    ThermometerDialView(outerDialSize: outerDialSize, degrees: CGFloat(temperature) / 40 * 360)
//                    ThermostatModeView(temperature: CGFloat(temperature), mode: $mode)
//                }
//            }
//            // Button for testing temperature change
//            Button("Increase Temperature") {
//                self.temperature += 1
//                postTemperatureUpdate(newTemperature: self.temperature)
//            }
//            Button("Decrease Temperature") {
//                self.temperature -= 1
//                postTemperatureUpdate(newTemperature: self.temperature)
//            }
//        }
//    }
//    
//    private func postTemperatureUpdate(newTemperature: Double) {
//        let entityId = room.entityId
//        climateService.sendTemperatureUpdate(entityId: entityId, temperature: Int(newTemperature), mode: mode)
//    }
//}
//
//struct ThermostatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ThermostatView(temperature: .constant(22), mode: .constant(.heat), room: Room.chambre)
//            .environmentObject(HalcyonViewModel())
//    }
//}




import SwiftUI

struct ThermostatView: View {
    @Binding var temperature: Double
    @Binding var mode: HvacModes
    var room: Room
    @EnvironmentObject var climateService: HalcyonViewModel
    
    private let baseRingSize: CGFloat = 180
    private let baseOuterDialSize: CGFloat = 170
    private let minTemperature: CGFloat = 10
    private let maxTemperature: CGFloat = 30
    
    private var ringSize: CGFloat { baseRingSize }
    private var outerDialSize: CGFloat { baseOuterDialSize }
    @State private var intermediateTemperature: Double // Local state to track crown input
    
    init(temperature: Binding<Double>, mode: Binding<HvacModes>, room: Room) {
        self._temperature = temperature
        self._mode = mode
        self.room = room
        self._intermediateTemperature = State(initialValue: temperature.wrappedValue) // Initialize with the current temperature
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ThermometerScaleView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Circle()
                    .trim(from: 0.25, to: min(CGFloat(climateService.temperature) / 40, 0.75))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("Temperature Ring 1"), Color("Temperature Ring 2")]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(90))
                    .animation(.linear(duration: 1), value: CGFloat(climateService.temperature) / 40)
                
                ThermometerDialView(outerDialSize: outerDialSize, degrees: CGFloat(climateService.temperature) / 40 * 360)
                ThermostatModeView(temperature: CGFloat(climateService.temperature), mode: Binding(get: { climateService.mode }, set: { climateService.mode = $0 }))
            }
            .focusable()
            .digitalCrownRotation($intermediateTemperature, from: Double(minTemperature), through: Double(maxTemperature), by: 1.0, sensitivity: .low, isContinuous: true)
            .onChange(of: intermediateTemperature) { newValue in
                postTemperatureUpdate(newTemperature: newValue)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Debounce
                    // Only update the temperature if it's different enough from the last sent value
                    // to avoid too frequent updates.
                    if abs(self.temperature - newValue) > 0.5 {
                        self.temperature = newValue
                        postTemperatureUpdate(newTemperature: newValue)
                    }
                }
            }
        }
    }
    
    private func postTemperatureUpdate(newTemperature: Double) {
        let entityId = room.entityId
        climateService.sendTemperatureUpdate(entityId: entityId, temperature: Int(newTemperature), mode: climateService.mode) { success in
            DispatchQueue.main.async {
                if success {
                    // Update the ViewModel's temperature to reflect the change
                    self.climateService.temperature = newTemperature
                } else {
                    // Handle error (e.g., show an error message or revert UI to previous state)
                }
            }
        }
    }
    
    
    struct ThermometerView_Previews: PreviewProvider {
        static var previews: some View {
            // Create a HalcyonViewModel instance
            let viewModel = HalcyonViewModel()
            // Use example values for the preview. Adjust as necessary.
            let temperatureBinding = Binding.constant(22.0)
            let modeBinding = Binding.constant(HvacModes.heat)
            
            return ThermostatView(temperature: temperatureBinding, mode: modeBinding, room: Room.chambre)
                .environmentObject(viewModel)
        }
    }

}
