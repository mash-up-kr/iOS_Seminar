//
//  ScheduleComponentView.swift
//  Mash-Up-iOS-OT
//
//  Created by GREEN on 2024/01/24.
//

import SwiftUI

struct ScheduleComponentView: View {
  let title: String
  let schedules: [(String, String)]
  
  init(
    title: String,
    schedules: [(String, String)]
  ) {
    self.title = title
    self.schedules = schedules
  }
  
  var body: some View {
    VStack(spacing: 50) {
      Spacer()
        .frame(height: 30)
      
      HStack {
        Text(title)
          .font(.system(size: 100))
          .bold()
          .foregroundStyle(.white)
        
        Spacer()
      }
      
      if schedules.isEmpty {
        EmptyScheduleView()
      } else {
        HStack {
          VStack(spacing: 20) {
            ForEach(schedules, id: \.0) { schedule in
              ScheduleCardView(schedule: schedule)
            }
          }
          
          Spacer()
        }
      }
      
      Spacer()
    }
  }
}

struct ScheduleCardView: View {
  let schedule: (String, String)
  
  init(schedule: (String, String)) {
    self.schedule = schedule
  }
  
  var body: some View {
    HStack(spacing: 30) {
      Text(schedule.0)
        .font(.system(size: 30))
        .bold()
        .foregroundStyle(.white)
      
      Text(schedule.1)
        .font(.system(size: 30))
        .bold()
        .foregroundStyle(.white.opacity(0.9))
      
      Spacer()
    }
    .frame(width: 800)
    .padding(.all, 20)
    .background(Color.init(red: 37/255, green: 42/255, blue: 56/255))
    .cornerRadius(20)
  }
}

struct EmptyScheduleView: View {
  var body: some View {
    Text("😃 플젝에 집중 😃")
      .font(.system(size: 150))
      .bold()
      .foregroundStyle(.white)
      .padding(.top, 150)
  }
}
