//
//  IntroView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct IntroView: View {
  @EnvironmentObject var pathModel: PathModel
  
  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture(perform: { pathModel.paths.append(.welcomeView) })
        .edgesIgnoringSafeArea(.all)
      
      Image("logo")
        .resizable()
        .frame(width: 100, height: 100)
        .padding(.trailing, 20)
      
      VStack {
        Spacer()
        
        HStack {
          Spacer()
          
          Text("Mash-Up iOS 14기")
            .font(.system(size: 100))
            .bold()
          
          Spacer()
        }
        
        Spacer()
      }
      
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
}
