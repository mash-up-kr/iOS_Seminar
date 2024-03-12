//
//  IndexView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct IndexView: View {
  @EnvironmentObject private var pathModel: PathModel
  let text = "오늘 진행순서입니다 😃"
  @State private var revealedCharacters = 0
  @State private var isEndRevealedCharacters: Bool = false
  @State private var isDisplayIndexComponentView: Bool = false
  @State private var isAvailableDisplayNextView: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture(perform: {
          if isEndRevealedCharacters {
            isDisplayIndexComponentView = true
          }
          if isAvailableDisplayNextView {
            pathModel.paths.append(.introduceView)
          }
        })
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack(spacing: 10) {
        Spacer()
        
        if !isDisplayIndexComponentView {
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
                IndexComponentView(order: 1, title: "🙋🏻 렛미인트로듀스마이셀프")
                IndexComponentView(order: 2, title: "🧐 스터디란 무엇인가")
                IndexComponentView(order: 3, title: "⁉️ 나는 누구랑 팀")
                IndexComponentView(order: 4, title: "🤔 7개월간 우리의 여정")
                IndexComponentView(order: 5, title: "📥 전달사항")
                IndexComponentView(order: 6, title: "📣 상희's 세미나")
                IndexComponentView(order: 7, title: "📣 영균's 세미나")
                IndexComponentView(order: 8, title: "🍻 먹고마시고죽자")
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

private struct IndexComponentView: View {
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
        .font(.system(size: 25))
        .bold()
        .padding(.all, 20)
        .background(Color.init(red: 255/255, green: 59/255, blue: 105/255))
        .cornerRadius(20)
        .opacity(isVisible ? 1.0 : 0.0)
      
      Text(title)
        .font(.system(size: 35))
        .bold()
        .opacity(isVisible ? 1.0 : 0.0)
      
      Spacer()
    }
    .frame(width: 600)
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
