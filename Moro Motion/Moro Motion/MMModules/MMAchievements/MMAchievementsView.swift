//
//  MMAchievementsView.swift
//  Moro Motion
//
//

import SwiftUI

struct MMAchievementsView: View {
    @StateObject var user = ZZUser.shared
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel = ZZAchievementsViewModel()
    @State private var index = 0
    var body: some View {
        ZStack {
            
            VStack {
                ZStack {
                    
                    HStack {
                        Image(.achievementsHeadMM)
                            .resizable()
                            .scaledToFit()
                            .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:80)
                    }
                    
                    HStack(alignment: .top) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:60)
                        }
                        
                        Spacer()
                        
                        ZZCoinBg()
                    }.padding(.horizontal)
                }.padding([.top])
                
                Spacer()
                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        ForEach(viewModel.achievements, id: \.self) { item in
                            ZStack {
                                Image(item.isAchieved ? item.image : "\(item.image)off")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:230)
                                    .onTapGesture {
                                        if !item.isAchieved {
                                            user.updateUserMoney(for: 10)
                                        }
                                        viewModel.achieveToggle(item)
                                    }
                                
                            }
                        }
                        
                    }
                }
                Spacer()
            }
        }.background(
            ZStack {
                Image(.appBgMM)
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
            }
        )
    }
    
    
}

#Preview {
    MMAchievementsView()
}
