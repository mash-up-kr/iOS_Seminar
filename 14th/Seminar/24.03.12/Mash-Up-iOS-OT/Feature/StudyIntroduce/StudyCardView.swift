//
//  StudyCardView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct StudyCardView: View {
  let title: String
  let description: String
  @State private var isDisplayBack = false
  
  var body: some View {
    VStack {
      if isDisplayBack {
        back
      } else {
        front
      }
    }
    .rotation3DEffect(
      .degrees(isDisplayBack ? 180 : 0),
      axis: (x: 0, y: 1, z: 0)
    )
    .onTapGesture {
      withAnimation {
        isDisplayBack.toggle()
      }
    }
  }
  
  var front: some View {
    VStack {
      Text(title)
        .font(.system(size: 50))
        .bold()
        .foregroundStyle(.white)
    }
    .frame(width: 300, height: 300)
    .background(Color.init(red: 255/255, green: 77/255, blue: 85/255))
    .cornerRadius(10)
    .rotation3DEffect(
      .degrees(0),
      axis: (x: 0, y: 1, z: 0)
    )
  }
  
  var back: some View {
    VStack(spacing: 10) {
      Text(description)
        .font(.system(size: 40))
        .bold()
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
    }
    .frame(width: 300, height: 300)
    .background(Color.init(red: 75/255, green: 58/255, blue: 255/255))
    .cornerRadius(10)
    .rotation3DEffect(
      .degrees(180),
      axis: (x: 0, y: 1, z: 0)
    )
  }
}
