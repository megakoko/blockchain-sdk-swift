//
//  BlockchainSdkExampleView.swift
//  BlockchainSdkExample
//
//  Created by Andy on 23.12.2021.
//

import SwiftUI

struct BlockchainSdkExampleView: View {
    @StateObject var model = BlockchainSdkExampleViewModel()
    
    var body: some View {
        VStack(spacing: 40) {
            Button {
                model.scan()
            } label: {
                Text("Scan")
            }

            Button {
                model.sendSol()
            } label: {
                Text("Send SOL")
            }
            .disabled(model.card == nil)
            
            Button {
                model.sendToken()
            } label: {
                Text("Send tokens")
            }
            .disabled(model.card == nil)
            
            Button {
                model.getTokenWallets()
            } label: {
                Text("Get token wallets")
            }
            .disabled(model.card == nil)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainSdkExampleView()
    }
}
