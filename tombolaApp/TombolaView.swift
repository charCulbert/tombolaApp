//
//  TombolaView.swift
//  tombolaApp
//
//  Created by Charlie Culbert on 1/9/25.
//

import SwiftUI
import SpriteKit

#if os(iOS)
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
#else
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
#endif

/// SpriteKit view wrapper that works across iOS and macOS
struct SpriteView: PlatformViewRepresentable {
    let controller: TombolaController
    
    #if os(iOS)
    func makeUIView(context: Context) -> SKView {
        let view = controller.setupSKView()
        view.showsFPS = true
        view.showsPhysics = true
        view.showsNodeCount = true
        print("DEBUG: iOS SpriteView created")
        return view
    }
    
    func updateUIView(_ view: SKView, context: Context) {
        print("DEBUG: iOS SpriteView updated")
    }
    #else
    func makeNSView(context: Context) -> SKView {
        let view = controller.setupSKView()
        view.showsFPS = true
        view.showsPhysics = true
        view.showsNodeCount = true
        print("DEBUG: macOS SpriteView created")
        return view
    }
    
    func updateNSView(_ view: SKView, context: Context) {
        print("DEBUG: macOS SpriteView updated")
    }
    #endif
}

/// Main view for the Tombola app
/// Displays the physics simulation and control sliders
/// Uses TombolaController to manage state and user interactions
struct TombolaView: View {
    /// Controller that manages the app's state and logic
    /// StateObject ensures the controller persists for the view's lifetime
    @StateObject private var controller = TombolaController()
    
    var body: some View {
        VStack(spacing: 0) {
            // Physics simulation view
            SpriteView(controller: controller)
                .frame(maxWidth: .infinity,
                       minHeight: 400,
                       maxHeight: .infinity
                )
                .background(Color.black)
                .foregroundColor(.white)  // Add this line
            
            // Controls section
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    // Left column of controls
                    VStack {
                        // Gravity control
                        SliderControl(
                            title: "Gravity",
                            value: Binding(
                                get: { controller.model.gravityStrength },
                                set: { controller.updateGravity($0) }
                            ),
                            range: -0.9...0,
                            step: 0.01,
                            format: "%.2f"
                        )
                        
                        // Rotation control
                        SliderControl(
                            title: "Rotation",
                            value: Binding(
                                get: { controller.model.rotationSpeed },
                                set: { controller.updateRotationSpeed($0) }
                            ),
                            range: 0...1,
                            step: 0.01,
                            format: "%.2f"
                        )
                        
                        // Friction control
                        SliderControl(
                            title: "Friction",
                            value: Binding(
                                get: { controller.model.friction },
                                set: { controller.updateFriction($0) }
                            ),
                            range: 0...0.5,
                            step: 0.01,
                            format: "%.2f"
                        )
                    }
                    
                    // Right column of controls
                    VStack {
                        // Bounce control
                        SliderControl(
                            title: "Bounce",
                            value: Binding(
                                get: { controller.model.bounciness },
                                set: { controller.updateBounciness($0) }
                            ),
                            range: 0.7...0.999,
                            step: 0.001,
                            format: "%.3f"
                        )
                        
                        // Ball size control
                        SliderControl(
                            title: "Ball Size",
                            value: Binding(
                                get: { controller.model.ballSize },
                                set: { controller.updateBallSize($0) }
                            ),
                            range: 5...20,
                            step: 1,
                            format: "%.0f"
                        )
                        
                        // Add Ball button
                        Button(action: {
                            controller.addBall()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Add Ball")
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // Bottom controls
                VStack {
                    // Bottom control for escape holes
                    IntSliderControl(
                        title: "Escape Holes",
                        value: Binding(
                            get: { controller.model.holeCount },
                            set: { controller.updateHoleCount($0) }
                        ),
                        range: 0...8
                    )
                    
                    // Ball lifetime control
                    SliderControl(
                        title: "Ball Lifetime (sec)",
                        value: Binding(
                            get: { controller.model.decayTime },
                            set: { controller.updateDecayTime($0) }
                        ),
                        range: 0...30,
                        step: 0.5,
                        format: "%.1f"
                    )
                }
            }
            .padding()
            .background(Color(.darkGray))
            .foregroundColor(.white)
                
        
        }
    }
}

struct TombolaView_Previews: PreviewProvider {
    static var previews: some View {
        TombolaView()
    }
}
