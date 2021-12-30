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
        VStack(spacing: 20) {
            Button {
                model.test()
            } label: {
                Text("Test")
            }
            
            Button {
                model.scan()
            } label: {
                Text("Scan")
            }
            
            
            Button {
                model.sign()
            } label: {
                Text("Sign")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BlockchainSdkExampleView()
    }
}
