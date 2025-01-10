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
        view.showsFPS = false
        view.showsPhysics = false
        view.showsNodeCount = false
        print("DEBUG: iOS SpriteView created")
        return view
    }
    
    func updateUIView(_ view: SKView, context: Context) {
        print("DEBUG: iOS SpriteView updated")
    }
    #else
    func makeNSView(context: Context) -> SKView {
        let view = controller.setupSKView()
        view.showsFPS = false
        view.showsPhysics = false
        view.showsNodeCount = false
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
            ZStack {
                SpriteView(controller: controller)
                    .frame(maxWidth: .infinity,
                           minHeight: 400,
                           maxHeight: .infinity
                    )
                    .background(Color.black)
                
                // Add Ball button overlay
                VStack {
                    Spacer()
                    Button(action: {
                        controller.addBall()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Ball")
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 16)
                }
            }
            
            // Controls section
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    // Left column of controls
                    VStack(spacing: 8) {
                        // Gravity control
                        SliderControl(
                            title: "Gravity",
                            value: Binding(
                                get: { controller.model.gravityStrength },
                                set: { controller.updateGravity($0) }
                            ),
                            range: -2.0...0,
                            step: 0.1,
                            format: "%.1f"
                        )
                        
                        // Rotation control
                        SliderControl(
                            title: "Rotation",
                            value: Binding(
                                get: { controller.model.rotationSpeed },
                                set: { controller.updateRotationSpeed($0) }
                            ),
                            range: 0...5.0,
                            step: 0.1,
                            format: "%.1f"
                        )
                    }
                    
                    // Right column of controls
                    VStack(spacing: 8) {
                        // Restitution control
                        SliderControl(
                            title: "Restitution",
                            value: Binding(
                                get: { controller.model.restitution },
                                set: { controller.updateRestitution($0) }
                            ),
                            range: 0.0...1.0,
                            step: 0.01,
                            format: "%.2f"
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
                    }
                }
                .padding(.top, 12)
                
                // Bottom controls
                VStack(spacing: 8) {
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
                .padding(.bottom, 16)
            }
            .padding(.horizontal)
            .background(Color(.darkGray))
            .foregroundColor(.white)
        }
    }
}

struct TombolaView_Previews: PreviewProvider {
    static var previews: some View {
        TombolaView()
            .frame(width: 800, height: 600)
    }
}
