import SwiftUI

struct ThermostatView: View {
    @Binding var temperature: Double
    @Binding var mode: HvacModes // Add binding for HVAC mode
    var room: Room
    @EnvironmentObject var climateService: HalcyonViewModel
    
    private let baseRingSize: CGFloat = 180
    private let baseOuterDialSize: CGFloat = 170
    private let minTemperature: CGFloat = 10
    private let maxTemperature: CGFloat = 30
    
    private var ringSize: CGFloat { baseRingSize }
    private var outerDialSize: CGFloat { baseOuterDialSize }
    
    init(temperature: Binding<Double>, mode: Binding<HvacModes>, room: Room) {
         self._temperature = temperature
         self._mode = mode // Initialize the mode binding
         self.room = room
     }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ThermometerScaleView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Circle()
                    .trim(from: 0.25, to: min(CGFloat(temperature) / 40, 0.75))
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
                    .animation(.linear(duration: 1), value: CGFloat(temperature) / 40)
                
                ThermometerDialView(outerDialSize: outerDialSize, degrees: CGFloat(temperature) / 40 * 360)
                ThermostatModeView(temperature: CGFloat(temperature), mode: $mode)
            }
            .focusable()
            .digitalCrownRotation(
                $temperature,
                from: Double(minTemperature),
                through: Double(maxTemperature),
                by: 1.0,
                sensitivity: .low,
                isContinuous: true
            )
            .onChange(of: temperature) { newTemperature in
                postTemperatureUpdate(newTemperature: newTemperature)
            }
        }
    }
    
    private func postTemperatureUpdate(newTemperature: Double) {
        let entityId = room.entityId
        climateService.sendTemperatureUpdate(entityId: entityId, mode: mode, temperature: Int(newTemperature))
    }
}
struct ThermometerView_Previews: PreviewProvider {
    static var previews: some View {
        ThermostatView(temperature: .constant(22), mode: .constant(.heat), room: Room.chambre)
    }
}

