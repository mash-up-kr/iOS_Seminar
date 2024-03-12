//
//  WelcomeView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct WelcomeView: View {
  @EnvironmentObject private var pathModel: PathModel
  let text = "14기 새 멤버를 소개합니다🙋🏻"
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  @State private var isDisplayCardView: Bool = false
  @State private var isAvailableDisplayNextView: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            isDisplayCardView = true
          }
          if isAvailableDisplayNextView {
            pathModel.paths.append(.indexView)
          }
        })
        .edgesIgnoringSafeArea(.all)
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack {
        Spacer()
        
        if !isDisplayCardView {
          HStack {
            Spacer()
            
            Text(String(text.prefix(revealedCharacters)))
              .font(.system(size: 100))
              .bold()
            
            Spacer()
          }
        } else {
          HStack(spacing: 20) {
            Spacer()
            
            Group {
              CardView(imageName: "jongyoon", name: "김종윤", description: "🍏 >>>>>>> 🌱")
              CardView(imageName: "junhyuk", name: "양준혁", description: "파브르형 개발자🐛")
              CardView(imageName: "hyeryeong", name: "장혜령", description: "요리 중수 iOS 개발자👩‍🍳")
              CardView(imageName: "hyuna", name: "송현아", description: "디발자 바로 나야 나💪")
            }
            .onAppear {
              isAvailableDisplayNextView = true
            }
            
            Spacer()
          }
        }
        
        Spacer()
      }
    }
    .toolbar(.hidden)
    .onAppear {
      animateText()
    }
  }
  
  func animateText() {
    guard revealedCharacters < text.count else {
      isEndRevealedCharacters = true
      return
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      revealedCharacters += 1
      animateText()
    }
  }
}
