//
//  TeamComponentView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct TeamComponentView: View {
  let title: String
  let members: [Member]
  
  init(
    title: String,
    members: [Member]
  ) {
    self.title = title
    self.members = members
  }
  
  var body: some View {
    VStack(spacing: 150) {
      Spacer()
        .frame(height: 30)
      
      HStack {
        Text(title)
          .font(.system(size: 100))
          .bold()
          .foregroundStyle(.white)
        
        Spacer()
      }
      
      HStack(spacing: 150) {
        ForEach(members, id: \.order) { member in
          TeamCardView(member: member)
        }
      }
      
      Spacer()
    }
  }
}

private struct TeamCardView: View {
  let member: Member
  @State private var opacity: Double = 0.0
  
  init(member: Member) {
    self.member = member
  }
  
  var body: some View {
    VStack(spacing: 10) {
      Image(member.image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 200, height: 200)
        .cornerRadius(10)
        .opacity(opacity)
      
      Text(member.name)
        .font(.system(size: 50))
        .bold()
        .foregroundStyle(.white)
        .opacity(opacity)
    }
    .onAppear {
      withAnimation(.easeIn(duration: 2.0)) {
        opacity = 1.0
      }
    }
  }
}
