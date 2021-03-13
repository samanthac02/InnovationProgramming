/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The sample app's main view controller.
*/

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var arView: ARView!
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-1.0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    let joints = ["head_joint", "right_forearm_joint", "right_hand_joint", "right_upLeg_joint", "right_leg_joint", "right_toes_joint","left_forearm_joint", "left_hand_joint", "left_upLeg_joint", "left_leg_joint", "left_toes_joint"]
    var coordinates: [ [ Float ] ] = []
    var tPose: [ [ Float ] ] = [[0.046, 0.001, 0], [-0.266, 0, 0], [-0.268, 0, 0], [-0.101, -0.025, 0.001], [-0.421, 0, 0], [-0.149, 0, 0], [0.266, 0, 0], [0.268, 0, 0], [0.101, -0.025, 0.001], [0.421, 0, 0], [0.149, 0, 0]]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }

        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
   
            
            for joint in joints {
                let position = bodyAnchor.skeleton.localTransform(for: ARSkeleton.JointName(rawValue: "\(joint)"))![3]
                var x = position[0]
                var y = position[1]
                var z = position[2]
                coordinates.append([x, y, z])
                
                print("x:\(x), y:\(y), z:\(z)")
            }
            
            print("coordinates: \(coordinates)")
            coordinates = []
            
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
            }
        }
        
        print("------------")
    }
}
