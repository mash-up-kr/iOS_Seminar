//
//  AdditionalIntroduceView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct AdditionalIntroduceView: View {
  @EnvironmentObject private var pathModel: PathModel
  let text = "📥 전달사항"
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  @State private var isDisplayAdditionalIntroduceComponentView: Bool = false
  @State private var isAvailableDisplayNextView: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            isDisplayAdditionalIntroduceComponentView = true
          }
          if isAvailableDisplayNextView {
            pathModel.paths.append(.thanksView)
          }
        })
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack(spacing: 10) {
        Spacer()
        
        if !isDisplayAdditionalIntroduceComponentView {
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
            
            VStack(alignment: .leading, spacing: 20) {
              Group {
                AdditionalIntroduceComponentView(order: 1, title: "지각은 세미나 시작 후 11분~30분")
                AdditionalIntroduceComponentView(order: 2, title: "결석은 세미나 시작 후 31분~")
                AdditionalIntroduceComponentView(order: 3, title: "세미나 방식 & 원티드 요청사항")
                AdditionalIntroduceComponentView(order: 4, title: "취미 원데이클래스 & 자율 스터디")
                AdditionalIntroduceComponentView(order: 5, title: "iOS 세미나 발표자 모집 🙋🏻")
                AdditionalIntroduceComponentView(order: 6, title: "전체 세미나 발표자 모집 🙋🏻")
              }
            }
            
            Spacer()
          }
          .onAppear {
            isAvailableDisplayNextView = true
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

private struct AdditionalIntroduceComponentView: View {
  let order: Int
  let title: String
  @State private var isVisible: Bool = false

  init(
    order: Int,
    title: String
  ) {
    self.order = order
    self.title = title
  }

  var body: some View {
    HStack(spacing: 30) {
      Text(String(order))
        .font(.system(size: 30))
        .bold()
        .padding(.all, 20)
        .background(Color.init(red: 255/255, green: 59/255, blue: 105/255))
        .cornerRadius(20)
        .opacity(isVisible ? 1.0 : 0.0)
      
      Text(title)
        .font(.system(size: 40))
        .bold()
        .opacity(isVisible ? 1.0 : 0.0)
      
      Spacer()
    }
    .frame(width: 1000)
    .padding(.all, 15)
    .background(Color.init(red: 37/255, green: 42/255, blue: 56/255))
    .opacity(isVisible ? 1.0 : 0.0)
    .cornerRadius(20)
    .onAppear {
      withAnimation(.easeIn(duration: 0.5)) {
        isVisible = true
      }
    }
  }
}
