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

    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var imageView: UIImageView!
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [0.0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    // Coordinate and joints data
    let joints = ["head_joint", "right_forearm_joint", "right_hand_joint", "right_upLeg_joint", "right_leg_joint", "right_toes_joint","left_forearm_joint", "left_hand_joint", "left_upLeg_joint", "left_leg_joint", "left_toes_joint"]
    var coordinates: [ [ Float ] ] = [[0.046, 0.001, 0], [-0.266, 0, 0], [-0.268, 0, 0], [-0.101, -0.025, 0.001], [-0.421, 0, 0], [-0.149, 0, 0], [0.266, 0, 0], [0.268, 0, 0], [0.101, -0.025, 0.001], [0.421, 0, 0], [0.149, 0, 0]]
    var tPose: [ [ Float ] ] = [[0.046, 0.001, 0], [-0.266, 0, 0], [-0.268, 0, 0], [-0.101, -0.025, 0.001], [-0.421, 0, 0], [-0.149, 0, 0], [0.266, 0, 0], [0.268, 0, 0], [0.101, -0.025, 0.001], [0.421, 0, 0], [0.149, 0, 0]]
    
    // Timer variables
    var seconds = 60
    var timer = Timer()
    var isTimerRunning = false
    
    var m1: UIImage!
    var m2: UIImage!
    var m3: UIImage!
    var images: [UIImage]!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self

        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        
        m1 = UIImage(named: "easy_catpose v1")
        m2 = UIImage(named: "easy_catpose v2")
        m3 = UIImage(named: "Untitled_Artwork 14")
        images = [m1, m2, m3]
        
        play()
        
        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)

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
    
    func play() {
        self.imageView.animationImages = images
        self.imageView.animationDuration = 1.0
        self.imageView.animationRepeatCount = 1
        self.imageView.startAnimating()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
   
            // Records coordinate positions of joints
            for joint in joints {
                let position = bodyAnchor.skeleton.localTransform(for: ARSkeleton.JointName(rawValue: "\(joint)"))![3]
                var x = Float(round(1000 * (position[0]))/1000)
                var y = Float(round(1000 * (position[1]))/1000)
                var z = Float(round(1000 * (position[2]))/1000)
                //coordinates.append([x, y, z])
                
                switch joint {
                case "head_joint":
                    coordinates[0] = [x, y, z]
                case "right_forearm_joint":
                    coordinates[1] = [x, y, z]
                case "right_hand_joint":
                    coordinates[2] = [x, y, z]
                case "right_upLeg_joint":
                    coordinates[3] = [x, y, z]
                case "right_leg_joint":
                    coordinates[4] = [x, y, z]
                case "right_toes_joint":
                    coordinates[5] = [x, y, z]
                case "left_forearm_joint":
                    coordinates[6] = [x, y, z]
                case "left_hand_joint":
                    coordinates[7] = [x, y, z]
                case "left_upLeg_joint":
                    coordinates[8] = [x, y, z]
                case "left_leg_joint":
                    coordinates[9] = [x, y, z]
                case "left_toes_joint":
                    coordinates[10] = [x, y, z]
                default:
                    print()
                }
                
                //print("x:\(x), y:\(y), z:\(z)")
            }
            
            //print("coordinates: \(coordinates)")
            //coordinates = []
            
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
            }
        }
        runTimer()
        //print("------------")
    }
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
        
    }
    
    @objc func updateTimer() {
        if seconds == 0 {
            //compareCoordinates()
            timer.invalidate()
            compareCoordinates()
            //seconds = 60
        } else {
            seconds -= 1
        }
        print("seconds left: \(seconds)")
    }
    
    func compareCoordinates() {
        for index in 0...10 {
            for i in 0...2 {
                print((tPose[index][i]) - (coordinates[index][i]))
            }
        }
    }
}
