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
                model.test()
            } label: {
                Text("Test")
            }
            .disabled(model.card == nil)
            
            Button {
                model.tokenTest()
            } label: {
                Text("Token test")
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
