//
//  LottieView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
  private let animation: String
  
  init(
    animation: String
  ) {
    self.animation = animation
  }
  
  func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
    let view = UIView(frame: .zero)
    let animationView = LottieAnimationView()
    
    animationView.animation = LottieAnimation.named(animation)
    animationView.frame = view.bounds
    
    animationView.contentMode = .scaleAspectFit
    animationView.loopMode = .loop
    animationView.animationSpeed = 1
    view.addSubview(animationView)
    
    animationView.play()
    
    NSLayoutConstraint.activate([
      animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
      animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
    ])
    animationView.translatesAutoresizingMaskIntoConstraints = false
    
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
  }
}
