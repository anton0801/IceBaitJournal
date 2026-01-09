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
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
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
                
                TextField("Notes", text: $notes)
                
                Section(header: Text("Add Photo (Optional)")) {
                    Button("Select Photo") {
                        showingImagePicker = true
                    }
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                    }
                }
            }
            .navigationTitle("Add Entry")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let depthDouble = Double(depth)
                    var photoData: Data? = nil
                    if let image = selectedImage, let jpeg = image.jpegData(compressionQuality: 0.8) {
                        photoData = jpeg
                    }
                    let entry = BaitEntry(
                        date: date,
                        baitType: baitType,
                        baitName: baitName,
                        fishType: fishType,
                        result: result,
                        iceCondition: iceCondition,
                        depth: depthDouble,
                        notes: notes,
                        photoData: photoData
                    )
                    dataManager.entries.append(entry)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .background(LinearGradient(gradient: Gradient(colors: [.iceWhite, .lightIceBlue]), startPoint: .top, endPoint: .bottom))
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
}


struct LocationSaveUseCase {
    func activate(locStr: String, finalLoc: URL) {
        let programStore = ProgramStateStoreImpl()
        programStore.archiveLocation(locStr)
        programStore.defineProgramStatus("JournalView")
        programStore.markStartCompleted()
    }
}

struct ObsoleteSwitchUseCase {
    func activate() {
        let programStore = ProgramStateStoreImpl()
        programStore.defineProgramStatus("Inactive")
        programStore.markStartCompleted()
    }
}

struct AuthBypassUseCase {
    func activate() {
        let authStore = AuthStateStoreImpl()
        authStore.defineLastAuthQuery(Date())
    }
}

struct AuthConfirmUseCase {
    func activate(confirmed: Bool) {
        let authStore = AuthStateStoreImpl()
        authStore.confirmAuth(confirmed)
        if !confirmed {
            authStore.rejectAuth(true)
        }
    }
}
