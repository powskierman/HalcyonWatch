import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HalcyonViewModel(restClient: .shared)
    @State private var selectedTemperature: Double = 22
    @State private var selectedRoom: Room = .chambre
    @State private var temperaturesForRooms: [Room: Double] = Room.allCases.reduce(into: [:]) { $0[$1] = 22 }
    @State private var hvacModesForRooms: [Room: HvacModes] = Room.allCases.reduce(into: [:]) { $0[$1] = .off }

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
            .onChange(of: selectedRoom) { newRoom in
                viewModel.fetchState(for: "climate.\(newRoom.rawValue)")
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(selectedRoom.rawValue)
        }
    }

    private func bindingFor(room: Room) -> Binding<Double> {
        Binding(
            get: { self.temperaturesForRooms[room, default: 22] },
            set: { self.temperaturesForRooms[room] = $0 }
        )
    }

    private func hvacModeBindingFor(room: Room) -> Binding<HvacModes> {
        Binding(
            get: { self.hvacModesForRooms[room, default: .off] },
            set: { self.hvacModesForRooms[room] = $0 }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(HalcyonViewModel(restClient: .shared)) // This is where you add the environment object
    }
}
