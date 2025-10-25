//
//  MMDailyView.swift
//  Moro Motion
//
//

import SwiftUI

struct MMDailyView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isReceived = false
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    Image(.personImg3MM)
                        .resizable()
                        .scaledToFit()
                        .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 140:300)
                        .offset(y: 30)
                    Spacer()
                }.ignoresSafeArea()
            }
            VStack {
                
                
                ZStack {
                    
                    Image(.dailyBgMM)
                        .resizable()
                        .scaledToFit()
                    
                    VStack {
                        Spacer()
                        
                        Button {
                            if !isReceived {
                                ZZUser.shared.updateUserMoney(for: 20)
                            }
                            isReceived.toggle()
                        } label: {
                            Image(isReceived ? .collectedBtnMM : .collectBtnMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 88:60)
                        }
                        
                    }.offset(y: -15)
                    
                }.frame(height: ZZDeviceManager.shared.deviceType == .pad ? 88:330)
                
            }
            
            VStack {
                ZStack {
                    
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                            
                        } label: {
                            Image(.backIconMM)
                                .resizable()
                                .scaledToFit()
                                .frame(height: ZZDeviceManager.shared.deviceType == .pad ? 100:55)
                        }
                        
                        Spacer()
                        
                        ZZCoinBg()
                        
                    }.padding()
                }
                Spacer()
                
            }
        }.frame(maxWidth: .infinity)
            .background(
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
    MMDailyView()
}
