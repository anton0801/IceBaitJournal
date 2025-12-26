import SwiftUI

struct AddEntryView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var date = Date()
    @State private var baitType: BaitType = .jig
    @State private var baitName = ""
    @State private var fishType: FishType = .perch
    @State private var result: Result = .noBites
    @State private var iceCondition: IceCondition = .normal
    @State private var depth: String = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                
                Picker("Bait Type", selection: $baitType) {
                    ForEach(BaitType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                TextField("Bait Name", text: $baitName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Fish Type", selection: $fishType) {
                    ForEach(FishType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
                Picker("Result", selection: $result) {
                    ForEach(Result.allCases, id: \.self) { res in
                        Text(res.rawValue).tag(res)
                    }
                }
                
                Picker("Ice Conditions", selection: $iceCondition) {
                    ForEach(IceCondition.allCases, id: \.self) { cond in
                        Text(cond.rawValue).tag(cond)
                    }
                }
                
                TextField("Depth (optional)", text: $depth)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Notes", text: $notes)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .navigationTitle("Add Entry")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let depthDouble = Double(depth)
                    let entry = BaitEntry(
                        date: date,
                        baitType: baitType,
                        baitName: baitName,
                        fishType: fishType,
                        result: result,
                        iceCondition: iceCondition,
                        depth: depthDouble,
                        notes: notes
                    )
                    dataManager.entries.append(entry)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
        }
    }
}
