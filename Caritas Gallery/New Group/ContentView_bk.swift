import Foundation
import RealityKit
import SwiftUI
import Combine


struct ARModel {

   // self.LoadedModel = $LoadedModel
    var arView = ARVariables.arView
    
    mutating func raycastFunc(location: CGPoint) {
    guard let query = ARVariables.arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: .any)
          else { return }
    guard let result = ARVariables.arView.session.raycast(query).first
          else { return }
        
        let anchorEntity = AnchorEntity(world: result.worldTransform)
        let usdzE = try! Entity.loadModel(named: "Asset 5.usdz")
        anchorEntity.addChild(usdzE)
        usdzE.generateCollisionShapes(recursive: false)
         ARVariables.arView.scene.anchors.removeAll()
        anchorEntity.orientation = simd_quatf(angle: .pi*1.5, axis: SIMD3(x: 1, y: 0, z: 0))
        ARVariables.arView.scene.anchors.append(anchorEntity)
        ARVariables.arView.installGestures([.scale], for: usdzE)
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
    
    
    @State var cancellable: AnyCancellable? = nil
    let aanchor = AnchorEntity()
// var aarView = ARView(frame: .zero)

    
    var body: some View {
               
            ZStack(alignment: .bottom){
                 ARViewContainer(arViewModel: arViewModel).edgesIgnoringSafeArea(.all)
                    .onTapGesture(coordinateSpace: .global) { location in
                        arViewModel.raycastFunc(location: location)
                                            
                  
                                  }
                
                
                                  
                if showOverlay {
                                ZStack {
                                    
                             
                                   
                                   
                                    Color.white
                                    Color.white.opacity(0.5)
                                    Image("CHK 70th LOGO")
                                        .resizable()
                                        .scaledToFit()
                                        .opacity(imageOpacity)
                                }
                                .edgesIgnoringSafeArea(.all)
                                .onAppear {
                                    DispatchQueue.main.async {
                                        cancellable = Entity.loadModelAsync(named: "Asset 1.usdz").sink(
                                            
                                            receiveCompletion: { completion in
                                                if case let .failure(error) = completion {
                                                    print("Unable to load a model due to \(error)")
                                                }
                                                self.cancellable?.cancel()
                                                
                                            }, receiveValue: { [self] (model: Entity) in
                                                print("model loaded !!")
                                                // aanchor.addChild(model)
                                                //LoadedModel = model
                                                //aanchor.position.z = -1.0
                                                //aarView.scene.anchors.append(aanchor)
                                            })
                                    }
                                    
                                    withAnimation(.easeInOut(duration: 5)) {
                                    
                                        imageOpacity = 1.0
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                            withAnimation {
                                                self.showOverlay = false
                                            }
                                        }
                                    }}
                            }
                    
                
                VStack{
                    
                 /*  Spacer(minLength: 1)
                    //Image("CHK 70th LOGO")
                    Image(systemName: "heart.fill")
                        //.foregroundColor(.white)
                        .resizable()
                        .padding(.leading, 3.0)
                        .scaledToFit()
                        .frame(width: 370, height: 370)
                        .opacity(imageOpacity)
                                        .onAppear {
                                            withAnimation(.easeInOut(duration: 1)) {
                                            //    let usdzE = try! Entity.loadModel(named: "Asset 5.usdz")
                                                /*  DispatchQueue.main.async {
                                                      cancellable = Entity.loadModelAsync(named: "Asset 1.usdz").sink(
                                                          
                                                          receiveCompletion: { completion in
                                                              if case let .failure(error) = completion {
                                                                  print("Unable to load a model due to \(error)")
                                                              }
                                                              self.cancellable?.cancel()
                                                              
                                                          }, receiveValue: { [self] (model: Entity) in
                                                              print("model loaded !!")
                                                              aanchor.addChild(model)
                                                              //LoadedModel = model
                                                              aanchor.position.z = -1.0
                                                              aarView.scene.anchors.append(aanchor)
                                                          })
                                                      
                                                  }*/
                                                
                                                imageOpacity = 1.0
                                            }
                                        }
                    Spacer(minLength: 300)*/
                    
                    
                    Button (action:  {
              showAlert = true
                        ARVariables.arView.snapshot(saveToHDR: false) { (image) in
                            let compressedImage = UIImage(data: (image?.pngData())!)
                            // Save in the photo album
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
                    .alert(isPresented: $showAlert, content: {
                      
                        Alert(
                                       title: Text("Photo is saved"),
                                       message: Text("You may continue or exit"),
                                       primaryButton: .destructive(Text("Exit")) {
                                           UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                                                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                   exit(0)
                                                               }
                                       },
                                       secondaryButton: .default(Text("Continue"))
                                   )
                            })
                                           //.alert("Please tap to place Caritas Gallery logo", isPresented: $isPresent){}
                }
                
                
              
                
            }
     }
}


