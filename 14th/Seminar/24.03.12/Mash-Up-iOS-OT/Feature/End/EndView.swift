//
//  EndView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct EndView: View {
  @EnvironmentObject var pathModel: PathModel
  @State var isDisplayLastMentView: Bool = false
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
        .onTapGesture {
          isDisplayLastMentView = true
        }
      
      VStack {
        Spacer()
        
        if !isDisplayLastMentView {
          HStack {
            Spacer()
            
            ExplodingView()
            
            Spacer()
          }
        } else {
          HStack {
            Spacer()
            
            Text("🍏 최강 iOS 14기 가보자고~ 🤿")
              .font(.system(size: 100))
              .bold()
            
            Spacer()
          }
        }
        
        Spacer()
      }
      
      if isDisplayLastMentView {
        VStack {
          HStack {
            LottieView(animation: "diving")
              .frame(width: 400)
            
            Spacer()
          }
          
          Spacer()
          
          HStack {
            Spacer()
            
            LottieView(animation: "diving")
              .frame(width: 400)
          }
        }
      }
    }
    .toolbar(.hidden)
  }
}

struct ExplodingView: View {
  @State private var explode = true
  let offsets: [[CGPoint]] = (0..<10)
    .map {
      _ in (0..<10)
        .map {
          _ in CGPoint(
            x: CGFloat.random(in: -300...300),
            y: CGFloat.random(in: -300...300))
        }
    }
  let rotations: [[Double]] = (0..<10)
    .map {
      _ in (0..<10)
        .map {
          _ in Double.random(in: 0...360)
        }
    }
  
  var body: some View {
    VStack(spacing: 0) {
      ForEach(0..<10) { row in
        HStack(spacing: 0) {
          ForEach(0..<10) { column in
            Image("\(row)\(column)")
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 120, height: 67)
              .offset(
                x: self.explode ? self.offsets[row][column].x : 0,
                y: self.explode ? self.offsets[row][column].y : 0
              )
              .rotationEffect(.degrees(self.explode ? self.rotations[row][column] : 0))
              .animation(Animation.spring().delay(Double.random(in: 0...3)), value: explode)
              .animation(.spring, value: explode)
          }
        }
      }
    }
    .onTapGesture {
      self.explode.toggle()
    }
  }
}
