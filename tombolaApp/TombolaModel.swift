//
//  TombolaModel.swift
//  tombolaApp
//
//  Created by Charlie Culbert on 1/9/25.
//

import Foundation
import CoreGraphics
import SwiftUI

/// Represents a single ball in the physics simulation
struct Ball {
    /// Position of the ball in the scene's coordinate space
    var position: CGPoint
    /// Color of the ball (cycles through a predefined set)
    var color: Color
    /// Radius of the ball in points
    var size: CGFloat
    /// Time when the ball was created
    var creationTime: TimeInterval
}

/// Data model for the Tombola physics simulation
/// This struct contains all the configurable parameters that affect the simulation
/// but contains no logic - just pure data
struct TombolaModel {
    // MARK: - Physics Parameters
    
    /// Strength of gravity (negative for downward force)
    /// Range: -0.9...0
    var gravityStrength: CGFloat = -0.50
    
    /// Number of balls in the simulation
    /// Range: 1...20
    var ballCount: Int = 3
    
    /// Speed of rotation for the circular boundary
    /// Range: 0...1, where 0 is stationary
    var rotationSpeed: CGFloat = 0.50
    
    /// Bounciness of balls (1.0 = perfect bounce, 0.0 = no bounce)
    /// Range: 0.7...0.999
    var bounciness: CGFloat = 0.99
    
    /// Friction coefficient for ball-wall collisions
    /// Range: 0...0.5
    var friction: CGFloat = 0.02
    
    /// Size (radius) of each ball in points
    /// Range: 5...20
    var ballSize: CGFloat = 8
    
    /// Number of holes in the circular boundary
    /// Range: 0...8
    var holeCount: Int = 0
    
    /// Decay time in seconds for balls (0 means no decay)
    /// Range: 0...30
    var decayTime: CGFloat = 5
    
    // MARK: - Simulation State
    
    /// Current collection of balls in the simulation
    var balls: [Ball] = []
    
    /// Radius of the circular boundary in points
    let circleRadius: CGFloat = 180
    
    /// Available colors for balls (cycles through these)
    let ballColors: [Color] = [.blue, .red, .green, .yellow, .orange]
    
    // MARK: - Validation
    
    /// Ensures ball count stays within valid range
    /// Referenced by: TombolaController when updating ball count
    var validatedBallCount: Int {
        min(max(ballCount, 1), 20)
    }
    
    /// Ensures hole count stays within valid range
    /// Referenced by: TombolaController when updating hole count
    var validatedHoleCount: Int {
        min(max(holeCount, 0), 8)
    }
    
    // MARK: - Ball Generation
    
    /// Generates new balls with random positions within the boundary
    /// Called by: TombolaScene when updating ball count
    mutating func generateBalls() {
        balls.removeAll()
        for i in 0..<ballCount {
            var localPosition: CGPoint
            repeat {
                let angle = CGFloat.random(in: 0...(.pi * 2))
                let radius = CGFloat.random(in: 0...(circleRadius - ballSize * 1.5))
                localPosition = CGPoint(
                    x: cos(angle) * radius,
                    y: sin(angle) * radius
                )
            } while hypot(localPosition.x, localPosition.y) > circleRadius - ballSize * 1.5
            
            balls.append(Ball(
                position: localPosition,
                color: ballColors[i % ballColors.count],
                size: ballSize,
                creationTime: Date().timeIntervalSinceReferenceDate
            ))
        }
    }
    
    /// Checks if a given position is valid for a ball (inside boundary)
    /// Called by: TombolaScene when checking ball positions
    func isValidBallPosition(_ position: CGPoint) -> Bool {
        hypot(position.x, position.y) <= circleRadius - ballSize * 1.5
    }
}
