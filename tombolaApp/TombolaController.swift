//
//  TombolaController.swift
//  tombolaApp
//
//  Created by Charlie Culbert on 1/9/25.
//

import Foundation
import SwiftUI
import SpriteKit

/// Controller class that manages the interaction between the TombolaModel (data)
/// and the TombolaView/TombolaScene (presentation/physics)
class TombolaController: ObservableObject {
    /// The data model containing all simulation parameters
    /// Published so the view updates automatically when values change
    @Published private(set) var model: TombolaModel
    
    /// Reference to the physics scene
    /// Weak to avoid retain cycles since the scene is owned by SKView
    private weak var scene: TombolaScene?
    
    /// Creates a new controller with optional initial model
    /// - Parameter model: Initial model state, defaults to new model if not provided
    init(model: TombolaModel = TombolaModel()) {
        self.model = model
    }
    
    /// Creates and configures an SKView with the physics scene
    /// Called by: TombolaView when it first appears
    /// Returns: Configured SKView ready for display
    func setupSKView() -> SKView {
        print("DEBUG: Setting up SKView")
        let view = SKView()
        let scene = TombolaScene(size: CGSize(width: 400, height: 400))
        scene.scaleMode = .aspectFit
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Initialize scene with current model values
        scene.gravityStrength = model.gravityStrength
        scene.ballCount = model.ballCount
        scene.rotationSpeed = model.rotationSpeed
        scene.bounciness = model.bounciness
        scene.friction = model.friction
        scene.ballSize = model.ballSize
        scene.holeCount = model.holeCount
        scene.remainingLifetimeNormalized = model.decayTime
        
        print("DEBUG: Scene created with:")
        print("DEBUG: - Gravity: \(model.gravityStrength)")
        print("DEBUG: - Balls: \(model.ballCount)")
        print("DEBUG: - Rotation: \(model.rotationSpeed)")
        print("DEBUG: - Decay: \(model.decayTime)")
        
        view.presentScene(scene)
        view.showsPhysics = true
        view.showsFPS = true
        view.showsNodeCount = true
        view.ignoresSiblingOrder = true
        
        print("DEBUG: Scene presented to view")
        self.scene = scene
        return view
    }
    
    // MARK: - Model Updates
    // These methods are called by TombolaView in response to user interaction
    // They update both the model and the physics scene
    
    /// Updates gravity strength in model and physics
    func updateGravity(_ value: CGFloat) {
        // print("DEBUG: Updating gravity to \(value)")
        model.gravityStrength = value
        scene?.gravityStrength = value
    }
    
    /// Updates ball count in model and physics
    func updateBallCount(_ value: Int) {
        // print("DEBUG: Updating ball count to \(value)")
        model.ballCount = value
        scene?.ballCount = value
    }
    
    /// Updates rotation speed in model and physics
    func updateRotationSpeed(_ value: CGFloat) {
        // print("DEBUG: Updating rotation to \(value)")
        model.rotationSpeed = value
        scene?.rotationSpeed = value
    }
    
    /// Updates bounciness in model and physics
    func updateBounciness(_ value: CGFloat) {
        // print("DEBUG: Updating bounciness to \(value)")
        model.bounciness = value
        scene?.bounciness = value
    }
    
    /// Updates friction in model and physics
    func updateFriction(_ value: CGFloat) {
        // print("DEBUG: Updating friction to \(value)")
        model.friction = value
        scene?.friction = value
    }
    
    /// Updates ball size in model and physics
    func updateBallSize(_ value: CGFloat) {
        // print("DEBUG: Updating ball size to \(value)")
        model.ballSize = value
        scene?.ballSize = value
    }
    
    /// Updates hole count in model and physics
    func updateHoleCount(_ value: Int) {
        // print("DEBUG: Updating hole count to \(value)")
        model.holeCount = value
        scene?.holeCount = value
    }
    
    /// Updates the decay time for balls
    /// - Parameter value: New decay time value (0-30 seconds)
    func updateDecayTime(_ value: CGFloat) {
        // print("DEBUG: Updating decay time to \(value)")
        model.decayTime = value
        scene?.remainingLifetimeNormalized = value
    }
    
    /// Adds a single ball to the simulation
    func addBall() {
        model.ballCount += 1
        scene?.ballCount = model.ballCount
    }
}
