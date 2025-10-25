//
//  ZZCoinBg.swift
//  Moro Motion
//
//


import SwiftUI

struct ZZCoinBg: View {
    @StateObject var user = ZZUser.shared
    var height: CGFloat = ZZDeviceManager.shared.deviceType == .pad ? 80:40
    var body: some View {
        ZStack {
            Image(.coinsBgMM)
                .resizable()
                .scaledToFit()
            
            Text("\(user.money)")
                .font(.system(size: ZZDeviceManager.shared.deviceType == .pad ? 45:24, weight: .black))
                .foregroundStyle(.black)
                .textCase(.uppercase)
                .offset(x: 15)
            
            
            
        }.frame(height: height)
        
    }
}

#Preview {
    ZZCoinBg()
}
