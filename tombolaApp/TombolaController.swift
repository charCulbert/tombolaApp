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
        scene.restitution = model.restitution
        scene.ballSize = model.ballSize
        scene.holeCount = model.holeCount
        scene.remainingLifetimeNormalized = model.decayTime
        
        print("DEBUG: Scene created with:")
        print("DEBUG: - Gravity: \(model.gravityStrength)")
        print("DEBUG: - Balls: \(model.ballCount)")
        print("DEBUG: - Rotation: \(model.rotationSpeed)")
        print("DEBUG: - Decay: \(model.decayTime)")
        
        view.presentScene(scene)
        view.showsPhysics = false  // Turn off physics debug visualization
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
        model.gravityStrength = value
        scene?.gravityStrength = value
    }
    
    /// Updates ball count in model and physics
    func updateBallCount(_ value: Int) {
        model.ballCount = value
        scene?.ballCount = value
    }
    
    /// Updates rotation speed in model and physics
    func updateRotationSpeed(_ value: CGFloat) {
        model.rotationSpeed = value
        scene?.rotationSpeed = value
    }
    
    /// Updates restitution in model and physics
    func updateRestitution(_ value: CGFloat) {
        model.restitution = value
        scene?.restitution = value
    }
    
    /// Updates ball size in model and physics
    func updateBallSize(_ value: CGFloat) {
        model.ballSize = value
        scene?.ballSize = value
    }
    
    /// Updates hole count in model and physics
    func updateHoleCount(_ value: Int) {
        model.holeCount = value
        scene?.holeCount = value
    }
    
    /// Updates the decay time for balls
    /// - Parameter value: New decay time value (0-30 seconds)
    func updateDecayTime(_ value: CGFloat) {
        model.decayTime = value
        scene?.remainingLifetimeNormalized = value
    }
    
    /// Adds a single ball to the simulation
    func addBall() {
        model.ballCount += 1
        scene?.addBallInRandomPosition()
    }
}
