//
//  BlockchainSdkTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import XCTest
import BitcoinCore

class BlockchainSdkTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDucatusAddressValidation() {
        XCTAssertTrue(Blockchain.ducatus.validate(address: "LokyqymHydUE3ZC1hnZeZo6nuART3VcsSU"))
    }
    
    func testLTCAddressValidation() {
        XCTAssertTrue(Blockchain.litecoin.validate(address: "LMbRCidgQLz1kNA77gnUpLuiv2UL6Bc4Q2"))
    }
    
    func testEthChecksum() {
        let ethAddressService = EthereumAddressService()
        let chesksummed = ethAddressService.toChecksumAddress("0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359")
        XCTAssertEqual(chesksummed, "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359")
        
        XCTAssertTrue(ethAddressService.validate("0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359"))
        XCTAssertTrue(ethAddressService.validate("0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"))
        
        let testCases = ["0x52908400098527886E0F7030069857D2E4169EE7",
                         "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
                         "0xde709f2102306220921060314715629080e2fb77",
                         "0x27b1fdb04752bbc536007a920d24acb045561c26",
                         "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed",
                         "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359",
                         "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB",
                         "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"]
        
        _ = testCases.map {
            let checksummed = ethAddressService.toChecksumAddress($0)
            XCTAssertNotNil(checksummed)
            XCTAssertTrue(ethAddressService.validate($0))
            XCTAssertTrue(ethAddressService.validate(checksummed!))
        }

        XCTAssertFalse(ethAddressService.validate("0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9adb"))
    }
    
    func testTxValidation() {
        let vm: WalletManager = BitcoinWalletManager(cardId: "",
                                      wallet: Wallet(blockchain: .bitcoin(testnet: false),
                                                     addresses: [PlainAddress(value: "adfjbajhfaldfh")]))
        
        vm.wallet.add(coinValue: 10)
        var errors = vm.validateTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 3),
                                            fee: Amount(with: vm.wallet.amounts[.coin]!, value: 3))
        XCTAssertTrue(errors.errors.isEmpty)

        errors = vm.validateTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: -1),
                                            fee: Amount(with: vm.wallet.amounts[.coin]!, value: 3))
        XCTAssertTrue(errors.errors.first! == (TransactionError.invalidAmount))
        
        
        errors = vm.validateTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: -1),
                                            fee: Amount(with: vm.wallet.amounts[.coin]!, value: -1))
        XCTAssertTrue(errors.errors.first! == (TransactionError.invalidFee))
        
        errors = vm.validateTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 11),
                                            fee: Amount(with: vm.wallet.amounts[.coin]!, value: 1))
        XCTAssertTrue(errors.errors.first! == (TransactionError.amountExceedsBalance))
        
        errors = vm.validateTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 1),
                                            fee: Amount(with: vm.wallet.amounts[.coin]!, value: 11))
        XCTAssertTrue(errors.errors.first! == (TransactionError.feeExceedsBalance))
        
        errors = vm.validateTransaction(amount: Amount(with: vm.wallet.amounts[.coin]!, value: 3),
                                            fee: Amount(with: vm.wallet.amounts[.coin]!, value: 8))
        XCTAssertTrue(errors.errors.first! == (TransactionError.totalExceedsBalance))
    }
}
