import SpriteKit

/// SpriteKit scene that handles the physics simulation
/// This is where all the actual physics calculations and animations happen
class TombolaScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Ball Class
    
    private class BallNode: SKShapeNode {
        let createdTime: TimeInterval
        var remainingLifetimeNormalized: TimeInterval  // Default lifetime in seconds
        var color: SKColor
        let parentCircleRadius: CGFloat
        var initialLifetime: TimeInterval
        var lifetime: TimeInterval
        private var lastUpdateTime: TimeInterval?
        private var lastDebugPrintTime: TimeInterval = 0
        private var _isExpired = false
        var isExpired: Bool {
            get { return _isExpired }
        }
        
        var normalizedLifetime: Double {
            return lifetime / initialLifetime
        }
        
        init(radius: CGFloat, color: SKColor, createdTime: TimeInterval, circleRadius: CGFloat) {
            self.createdTime = createdTime
            self.color = color
            self.parentCircleRadius = circleRadius
            self.remainingLifetimeNormalized = 5.0  // Default value if not set
            self.initialLifetime = remainingLifetimeNormalized
            self.lifetime = initialLifetime
            super.init()
            
            let rect = CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
            let circlePath = CGPath(ellipseIn: rect, transform: nil)
            self.path = circlePath
            self.fillColor = color
            self.strokeColor = color
            self.name = "ball"
            
            // Set up physics body
            self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            self.physicsBody?.categoryBitMask = PhysicsCategory.ball.rawValue
            self.physicsBody?.collisionBitMask = PhysicsCategory.container.rawValue | PhysicsCategory.ball.rawValue | PhysicsCategory.hole.rawValue
            self.physicsBody?.contactTestBitMask = PhysicsCategory.container.rawValue | PhysicsCategory.ball.rawValue | PhysicsCategory.hole.rawValue
            self.physicsBody?.restitution = 0.8
            self.physicsBody?.linearDamping = 0.5
            self.physicsBody?.angularDamping = 0.5
            self.physicsBody?.friction = 0.2
            self.physicsBody?.allowsRotation = true
            self.physicsBody?.mass = 1.0
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func updateLifetime(currentTime: TimeInterval) -> TimeInterval {
            if let lastUpdate = lastUpdateTime {
                let delta = currentTime - lastUpdate
                lifetime -= delta
                
                // Fade out as lifetime decreases
                alpha = CGFloat(lifetime / initialLifetime)
                
                if lifetime <= 0 {
                    _isExpired = true
                }
            }
            
            lastUpdateTime = currentTime
            return lifetime
        }
        
        func colorToString() -> String {
            if self.color == .red { return "red" }
            if self.color == .green { return "green" }
            if self.color == .blue { return "blue" }
            if self.color == .yellow { return "yellow" }
            if self.color == .orange { return "orange" }
            if self.color == .purple { return "purple" }
            if self.color == .cyan { return "cyan" }
            return "unknown"
        }
    }
    
    // MARK: - Properties that sync with TombolaModel
    
    /// Gravity strength - negative means downward force
    /// Updated by: TombolaController.updateGravity()
    var gravityStrength: CGFloat = -0.20 {
        didSet {
            physicsWorld.gravity = CGVector(dx: 0, dy: gravityStrength)
        }
    }
    
    /// Number of balls in the simulation
    /// Updated by: TombolaController.updateBallCount()
    var ballCount: Int = 3 {
        didSet {
            updateBalls()
        }
    }
    
    /// Speed of boundary rotation
    /// Updated by: TombolaController.updateRotationSpeed()
    var rotationSpeed: CGFloat = 0.50 {
        didSet {
            updateRotation()
        }
    }
    
    /// Ball bounciness (1.0 = perfect bounce)
    /// Updated by: TombolaController.updateBounciness()
    var bounciness: CGFloat = 0.980 {
        didSet {
            updateBounciness()
        }
    }
    
    /// Surface friction coefficient
    /// Updated by: TombolaController.updateFriction()
    var friction: CGFloat = 0.02 {
        didSet {
            updateBounciness()
        }
    }
    
    /// Size (radius) of each ball
    /// Updated by: TombolaController.updateBallSize()
    var ballSize: CGFloat = 10 {
        didSet {
            updateBallSize()
        }
    }
    
    /// Number of holes in the boundary
    /// Updated by: TombolaController.updateHoleCount()
    var holeCount: Int = 1 {
        didSet {
            if holeCount > oldValue {
                // Add new holes until we reach the desired count
                while holeSegments.count < holeCount {
                    addHole()
                }
            } else if holeCount < oldValue {
                // Remove holes from the end until we reach the desired count
                while holeSegments.count > holeCount {
                    holeSegments.removeLast()
                }
            }
            createCircularBoundary()
        }
    }
    
    /// Decay time in seconds (0 means no decay)
    /// Updated by: TombolaController.updateDecayTime()
    var remainingLifetimeNormalized: CGFloat = 0
    
    // MARK: - Private Properties
    
    /// Collection of ball nodes in the scene
    private var balls: [BallNode] = []
    /// Radius of the circular boundary
    private let circleRadius: CGFloat = 180
    /// Reference to the container node that holds the boundary segments
    private var container: SKShapeNode?
    /// Ordered list of hole segment indices (0-15)
    private var holeSegments: [Int] = []
    private var previousBallSize: CGFloat = 10
    
    // MARK: - Physics Categories
    private enum PhysicsCategory: UInt32 {
        case none = 0
        case ball = 1
        case container = 2
        case hole = 4
        case escapeHole = 8
        case all = 0xFFFFFFFF  // Use hex literal for UInt32.max
    }
    
    // MARK: - Scene Setup
    
    /// Called when the scene is presented by SKView
    /// Initializes the physics world and creates initial objects
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityStrength)
        physicsWorld.contactDelegate = self
        
        createCircularBoundary()
        updateBalls()
    }
    
    /// Configures the physics world with initial settings
    private func setupPhysicsWorld() {
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityStrength)
        physicsWorld.contactDelegate = self
    }
    
    // MARK: - Boundary Creation
    
    /// Creates the circular boundary with holes
    /// This is the main container that holds the balls
    private func createCircularBoundary() {
        // Store current state
        let wasRotating = rotationSpeed > 0
        let currentAngularVelocity = container?.physicsBody?.angularVelocity ?? rotationSpeed
        let currentRotation = container?.zRotation ?? 0  // Store current rotation angle
        
        // Remove existing container if any
        container?.removeFromParent()
        
        let containerNode = SKShapeNode()
        containerNode.name = "container"
        
        // Create wall segments, skipping hole positions
        var segmentBodies: [SKPhysicsBody] = []
        let segmentArc = CGFloat.pi / 8  // 16 segments total
        
        for i in 0..<16 {
            if !holeSegments.contains(i) {
                let segmentBody = createWallSegment(index: i, arc: segmentArc)
                segmentBodies.append(segmentBody)
            }
        }
        
        // Create compound physics body
        let compoundBody = SKPhysicsBody(bodies: segmentBodies)
        setupWallPhysics(for: compoundBody)
        containerNode.physicsBody = compoundBody
        
        addChild(containerNode)
        container = containerNode
        
        // Restore rotation state and angle
        container?.zRotation = currentRotation  // Restore the rotation angle
        if wasRotating {
            container?.physicsBody?.angularVelocity = currentAngularVelocity
        }
    }
    
    /// Creates a new hole in the largest gap between existing holes
    private func addHole() {
        
        if holeSegments.isEmpty {
            // First hole goes at segment 0
            holeSegments.append(0)
            return
        }
        
        let sortedHoles = holeSegments.sorted()
        var largestGap = 0
        var insertAt = 0
        
        if sortedHoles.count == 1 {
            // With only one hole, put the second hole opposite to it
            insertAt = (sortedHoles[0] + 8) % 16
        } else {
            // Check gaps between consecutive holes
            for i in 0..<sortedHoles.count {
                let start = sortedHoles[i]
                let end = sortedHoles[(i + 1) % sortedHoles.count]
                let gap = (end - start + 16) % 16
                
                if gap > largestGap {
                    largestGap = gap
                    // Place new hole halfway between these holes
                    insertAt = (start + gap / 2) % 16
                }
            }
        }
        
        // Verify we're not duplicating a hole position
        if !holeSegments.contains(insertAt) {
            holeSegments.append(insertAt)
        } else {
            // Try the next available position
            for offset in 1...8 {
                let tryPos = (insertAt + offset) % 16
                if !holeSegments.contains(tryPos) {
                    holeSegments.append(tryPos)
                    break
                }
            }
        }
    }
    
    private func createWallSegment(index: Int, arc: CGFloat) -> SKPhysicsBody {
        let startAngle = CGFloat(index) * arc
        let endAngle = startAngle + arc
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: cos(startAngle) * circleRadius,
                            y: sin(startAngle) * circleRadius))
        path.addArc(center: .zero, radius: circleRadius,
                   startAngle: startAngle, endAngle: endAngle,
                   clockwise: false)
        
        let body = SKPhysicsBody(edgeChainFrom: path)
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.container.rawValue
        body.collisionBitMask = PhysicsCategory.ball.rawValue
        body.contactTestBitMask = PhysicsCategory.ball.rawValue
        body.restitution = bounciness
        body.friction = friction
        
        return body
    }
    
    private func setupWallPhysics(for body: SKPhysicsBody) {
        body.isDynamic = true
        body.pinned = true
        body.allowsRotation = true
        body.categoryBitMask = PhysicsCategory.container.rawValue
        body.collisionBitMask = PhysicsCategory.ball.rawValue
        body.contactTestBitMask = PhysicsCategory.ball.rawValue
        body.angularDamping = 0
    }
    
    // MARK: - Physics Updates
    
    /// Updates the physics properties of all objects
    private func updateBounciness() {
        container?.physicsBody?.restitution = bounciness
        
        for ball in balls {
            ball.physicsBody?.restitution = bounciness
            ball.physicsBody?.friction = friction
            ball.physicsBody?.linearDamping = 0
            ball.physicsBody?.angularDamping = 0
        }
    }
    
    /// Updates the rotation of the boundary
    private func updateRotation() {
        if rotationSpeed > 0 {
            if let body = container?.physicsBody {
                body.isDynamic = true
                body.pinned = true
                body.allowsRotation = true
                body.angularDamping = 0
                body.angularVelocity = rotationSpeed
            }
        } else {
            if let body = container?.physicsBody {
                body.angularVelocity = 0
                body.allowsRotation = false
                body.isDynamic = false
            }
        }
    }
    
    /// Updates the balls in the simulation based on count change
    private func updateBalls() {
        // Clear any expired balls
        balls.removeAll { ball in
            if ball.isExpired {
                ball.removeFromParent()
                return true
            }
            return false
        }
        
        // Add one new ball if requested
        if ballCount > balls.count {
            let ball = createBall(index: balls.count)
            balls.append(ball)
            addChild(ball)
            
            // Position the new ball near the center with a small random offset
            let randomOffset = CGFloat.random(in: -10...10)
            ball.position = CGPoint(x: randomOffset, y: randomOffset)
        }
    }
    
    /// Updates the ball size
    private func updateBallSize() {
        for (index, ball) in balls.enumerated() {
            // Preserve the current physics state
            let currentVelocity = ball.physicsBody?.velocity ?? .zero
            let currentAngularVelocity = ball.physicsBody?.angularVelocity ?? 0
            
            // Update the visual representation
            ball.path = CGPath(ellipseIn: CGRect(x: -ballSize, y: -ballSize,
                                                width: ballSize * 2, height: ballSize * 2),
                             transform: nil)
            
            // Create new physics body with updated size
            let body = SKPhysicsBody(circleOfRadius: ballSize)
            body.velocity = currentVelocity
            body.angularVelocity = currentAngularVelocity
            body.isDynamic = true
            body.affectedByGravity = true
            body.allowsRotation = true
            body.restitution = bounciness
            body.friction = friction
            body.mass = 1.0
            body.categoryBitMask = PhysicsCategory.ball.rawValue
            body.collisionBitMask = PhysicsCategory.container.rawValue | PhysicsCategory.ball.rawValue | PhysicsCategory.hole.rawValue
            body.contactTestBitMask = PhysicsCategory.container.rawValue | PhysicsCategory.ball.rawValue | PhysicsCategory.hole.rawValue
            
            ball.physicsBody = body
        }
    }
    
    /// Creates a new ball with specified properties
    private func createBall(index: Int) -> BallNode {
        let currentTime = Date().timeIntervalSinceReferenceDate
        let colors: [SKColor] = [.red, .green, .blue, .yellow, .orange, .purple, .cyan]
        
        let ball = BallNode(radius: ballSize,
                          color: colors[index % colors.count],
                          createdTime: currentTime,
                          circleRadius: circleRadius)
        ball.remainingLifetimeNormalized = TimeInterval(remainingLifetimeNormalized)
        ball.initialLifetime = ball.remainingLifetimeNormalized
        ball.lifetime = ball.initialLifetime
        
        return ball
    }
    
    // MARK: - Scene Updates
    
    /// Called every frame to update the simulation
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        
        // Update each ball's lifetime and remove if expired
        balls.removeAll { ball in
            let lifetime = ball.updateLifetime(currentTime: currentTime)
            if lifetime <= 0 {
                ball.removeFromParent()
                return true
            }
            return false
        }
        
        // Update ball sizes
        if ballSize != previousBallSize {
            updateBallSize()
            previousBallSize = ballSize
        }
    }
    
    // MARK: - Collision Handling
    
    /// Called when two physics bodies start contacting
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        // Ball-to-ball collision
        if firstBody.categoryBitMask == PhysicsCategory.ball.rawValue &&
           secondBody.categoryBitMask == PhysicsCategory.ball.rawValue,
           let ball1 = firstBody.node as? BallNode,
           let ball2 = secondBody.node as? BallNode {
            
            // Report collision for first ball
            let jsonString1 = String(format: """
                {"color":"%@","lifetimeRemaining":"%.2f","normalizedLifetimeRemaining":"%.3f","collidedWith":"ball"}
                """,
                ball1.colorToString(),
                ball1.lifetime,
                ball1.normalizedLifetime
            )
            print("Collision: \(jsonString1)")
            
            // Report collision for second ball
            let jsonString2 = String(format: """
                {"color":"%@","lifetimeRemaining":"%.2f","normalizedLifetimeRemaining":"%.3f","collidedWith":"ball"}
                """,
                ball2.colorToString(),
                ball2.lifetime,
                ball2.normalizedLifetime
            )
            print("Collision: \(jsonString2)")
        }
        // Ball-to-wall collision
        else if (firstBody.categoryBitMask == PhysicsCategory.ball.rawValue && 
                secondBody.categoryBitMask == PhysicsCategory.container.rawValue) ||
                (firstBody.categoryBitMask == PhysicsCategory.container.rawValue && 
                secondBody.categoryBitMask == PhysicsCategory.ball.rawValue) {
            let ball = (firstBody.categoryBitMask == PhysicsCategory.ball.rawValue) ? 
                      firstBody.node as? BallNode : 
                      secondBody.node as? BallNode
            if let ball = ball {
                let jsonString = String(format: """
                    {"color":"%@","lifetimeRemaining":"%.2f","normalizedLifetimeRemaining":"%.3f","collidedWith":"wall"}
                    """,
                    ball.colorToString(),
                    ball.lifetime,
                    ball.normalizedLifetime
                )
                print("Collision: \(jsonString)")
            }
        }
    }
    
    func addEscapeHole() {
        let holeRadius = circleRadius * 0.1
        let hole = SKShapeNode(circleOfRadius: holeRadius)
        hole.fillColor = .black
        hole.strokeColor = .clear
        
        // Calculate hole position based on container's current rotation
        let containerRotation = container?.zRotation ?? 0
        let x = circleRadius * cos(-containerRotation)
        let y = circleRadius * sin(-containerRotation)
        hole.position = CGPoint(x: x, y: y)
        
        hole.name = "escapeHole"
        hole.physicsBody = SKPhysicsBody(circleOfRadius: holeRadius)
        hole.physicsBody?.isDynamic = false
        hole.physicsBody?.categoryBitMask = PhysicsCategory.escapeHole.rawValue
        hole.physicsBody?.contactTestBitMask = PhysicsCategory.ball.rawValue
        container?.addChild(hole)
    }
    
    func removeEscapeHole() {
        if let hole = container?.childNode(withName: "escapeHole") {
            hole.removeFromParent()
        }
    }
}

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}
