import Foundation
import RealityKit
import SwiftUI
import Combine


struct ARModel {
   
    var arView = ARVariables.arView
    
    mutating func raycastFunc(location: CGPoint) {
        guard let query = ARVariables.arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: .any)
        else { return }
        guard let result = ARVariables.arView.session.raycast(query).first
        else { return }
        let anchorEntity = AnchorEntity(world: result.worldTransform)
        anchorEntity.addChild(ARVariables.myEnt)
        ARVariables.myEnt.generateCollisionShapes(recursive: false)
        ARVariables.arView.scene.anchors.removeAll()
        anchorEntity.orientation = simd_quatf(angle: .pi*1.5, axis: SIMD3(x: 1, y: 0, z: 0))
        ARVariables.arView.scene.anchors.append(anchorEntity)
        ARVariables.arView.installGestures([.scale], for: ARVariables.myEnt as! HasCollision)
        ARVariables.isRemind = false
    }
}

class ARViewModel: ObservableObject {
    
    @Published private var model : ARModel = ARModel()
   
    func raycastFunc(location: CGPoint) {
            model.raycastFunc(location: location)
    }
}

struct ARVariables{
    
    static var arView: ARView!
    @State var ccancellable: AnyCancellable? = nil
    let aanchor = AnchorEntity()
    static var myEnt: Entity!
    static var isRemind: Bool = true
}

struct ARViewContainer: UIViewRepresentable {
    var arViewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARView {
        ARVariables.arView = ARView(frame: .zero)
        return ARVariables.arView
     }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ContentView : View {
   
   
    @State var isPresent: Bool = true
    @State private var showAlert = false
    @ObservedObject var arViewModel : ARViewModel = ARViewModel()
    @State private var imageOpacity = 0.0
    @State private var showOverlay = true
    @State var isReady: Bool = false
    @State var cancellable: AnyCancellable? = nil
    @State private var isFlashVisible = false
    
    var body: some View {
        ZStack(alignment: .bottom){
            ARViewContainer(arViewModel: arViewModel).edgesIgnoringSafeArea(.all)
                .onTapGesture(coordinateSpace: .global) { location in
                    arViewModel.raycastFunc(location: location)
                }
            
            VStack{
                if isFlashVisible {
                          Text("Photo saved")
                        .foregroundColor(.blue)
                        .onAppear(){
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isFlashVisible = false
                            }
                        }
                      }
                
                
                if ARVariables.isRemind
                {
                    Text("Please tap to place Caritas Gallery logo")
                        .foregroundColor(.gray)
                        .font(.body)
                        .padding(.bottom, 300)
                    
                }
                
                  Button (action:  {
                      showAlert = true
                      isFlashVisible = true
                      ARVariables.arView.snapshot(saveToHDR: false) { (image) in
                          let compressedImage = UIImage(data: (image?.pngData())!)
                          UIImageWriteToSavedPhotosAlbum(compressedImage!, nil, nil, nil)
                      }
                                    }

              ,label: {
                      Image(systemName: "camera")
                          .frame(width:60, height:60)
                          .font(.title)
                          .background(.white.opacity(0.75))
                          .cornerRadius(30)
                          .padding()
                      
                  })
              }
            
            if showOverlay {
                ZStack {
                        Color.white
                    VStack{
                        Spacer(minLength: 0.1)
                        Image("CHK 70th LOGO")
                            .resizable()
                            .scaledToFit()
                            .opacity(imageOpacity)
                        Spacer(minLength: 350)
                    }
                    }
                
                .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        DispatchQueue.main.async { //entity model loaded async
                            cancellable = Entity.loadModelAsync(named: "Asset 5.usdz").sink(
                                receiveCompletion: { completion in
                                    if case let .failure(error) = completion {
                                        print("Unable to load a model due to \(error)")
                                    }
                                    self.cancellable?.cancel()
                                }, receiveValue: { [self] (model: Entity) in
                                    //print("model loaded !!")
                                    self.isReady = true
                                    ARVariables.myEnt = model
                                })
                        }
                        withAnimation(.easeInOut(duration: 5)) {
                            imageOpacity = 1.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation {
                                    if self.isReady {
                                        self.showOverlay = false
                                    }
                                }
                            }
                        }}
                }
            }
     }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
           // let sheet = SheetView(LoadedModel: $LoadedModel)
            }
}
