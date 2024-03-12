//
//  ThanksView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct ThanksView: View {
  @EnvironmentObject private var pathModel: PathModel
  let text = "🙇🏻 특별 감사인사 🙇🏻"
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  @State private var isDisplayThanksComponentView: Bool = false
  @State private var isAvailableDisplayNextView: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            isDisplayThanksComponentView = true
          }
          if isAvailableDisplayNextView {
            pathModel.paths.append(.sangheeSeminar)
          }
        })
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack(spacing: 10) {
        Spacer()
        
        if !isDisplayThanksComponentView {
          HStack {
            Spacer()
            
            Text(String(text.prefix(revealedCharacters)))
              .font(.system(size: 100))
              .bold()
            
            Spacer()
          }
        } else {
          HStack {
            Spacer()
            
            ThanksComponentView()
            
            Spacer()
          }
          .onAppear {
            isAvailableDisplayNextView = true
          }
        }
        
        Spacer()
      }
      
      if isDisplayThanksComponentView {
        VStack {
          HStack {
            LottieView(animation: "welcome")
              .frame(width: 400)
            
            Spacer()
          }
          
          Spacer()
          
          HStack {
            Spacer()
            
            LottieView(animation: "welcome")
              .frame(width: 400)
          }
        }
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

private struct ThanksComponentView: View {
  @EnvironmentObject private var pathModel: PathModel
  @State private var isAnimating = false
  
  var body: some View {
    ZStack {
      Image("wanted")
        .scaleEffect(isAnimating ? 3 : 1)
        .opacity(isAnimating ? 0 : 1)
        .animation(.easeInOut(duration: 3), value: isAnimating)
      
      Image("sanghoon")
        .scaleEffect(isAnimating ? 2 : 1)
        .opacity(isAnimating ? 1 : 0)
        .animation(.easeInOut(duration: 3).delay(3), value: isAnimating)
        .onTapGesture {
          pathModel.paths.append(.endView)
        }
    }
    .onAppear() {
      self.isAnimating = true
    }
  }
}
