import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel = HalcyonViewModel()
    @State private var selectedTemperature: Double = 22
    @State private var selectedRoom: Room = .chambre
    @State private var temperaturesForRooms: [Room: Double] = Room.allCases.reduce(into: [:]) { $0[$1] = 22 }
    @State private var hvacModesForRooms: [Room: HvacModes] = Room.allCases.reduce(into: [:]) { $0[$1] = .off }
    private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color("Background").ignoresSafeArea()
                    VStack(spacing: 0) {
                        TabView(selection: $selectedRoom) {
                            ForEach(Room.allCases, id: \.self) { room in
                                ThermostatView(
                                    temperature: self.bindingFor(room: room),
                                    mode: self.hvacModeBindingFor(room: room),
                                    room: room
                                )
                                .tag(room)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(width: geometry.size.width, height: geometry.size.width)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(selectedRoom.rawValue)
            .onChange(of: selectedRoom) { newRoom in
                   viewModel.fetchDeviceState(for: newRoom.rawValue)
             }
         }
    }

    private func bindingFor(room: Room) -> Binding<Double> {
        Binding(
            get: { temperaturesForRooms[room, default: 22] },
            set: { temperaturesForRooms[room] = $0 }
        )
    }

    private func hvacModeBindingFor(room: Room) -> Binding<HvacModes> {
        Binding(
            get: { hvacModesForRooms[room, default: .off] },
            set: { hvacModesForRooms[room] = $0 }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(HalcyonViewModel()) // This is where you add the environment object
    }
}
