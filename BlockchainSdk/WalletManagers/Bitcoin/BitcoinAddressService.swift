//
//  BitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import HDWalletKit
import BitcoinCore

public class BitcoinAddressService: AddressService {
    let legacy: BitcoinLegacyAddressService
    let bech32: BitcoinBech32AddressService
    
    init(networkParams: INetwork) {
        legacy = BitcoinLegacyAddressService(networkParams: networkParams)
        bech32 = BitcoinBech32AddressService(networkParams: networkParams)
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        return bech32.makeAddress(from: walletPublicKey)
    }
    
    public func validate(_ address: String) -> Bool {
        legacy.validate(address) || bech32.validate(address)
    }
    
    public func makeAddresses(from walletPublicKey: Data) -> [Address] {
        let bech32AddressString: String = bech32.makeAddress(from: walletPublicKey)
        let legacyAddressString: String = legacy.makeAddress(from: walletPublicKey)
      
        let bech32Address = BitcoinAddress(type: .bech32, value: bech32AddressString)
        
        let legacyAddress = BitcoinAddress(type: .legacy, value: legacyAddressString)
        
        return [bech32Address, legacyAddress]
    }
	
	public func make1Of2MultisigAddresses(firstPublicKey: Data, secondPublicKey: Data) throws -> [Address] {
		guard let script = try create1Of2MultisigOutputScript(firstPublicKey: firstPublicKey, secondPublicKey: secondPublicKey) else {
			throw BlockchainSdkError.failedToCreateMultisigScript
		}
        let legacyAddressString: String = legacy.makeMultisigAddress(from: script.data.sha256Ripemd160)
		let scriptAddress = BitcoinScriptAddress(script: script, value: legacyAddressString, type: .legacy)
        let bech32AddressString: String = bech32.makeMultisigAddress(from: script.data.sha256())
		let bech32Address = BitcoinScriptAddress(script: script, value: bech32AddressString, type: .bech32)
		return [bech32Address, scriptAddress]
	}
	
	private func create1Of2MultisigOutputScript(firstPublicKey: Data, secondPublicKey: Data) throws -> HDWalletScript? {
		var pubKeys = try [firstPublicKey, secondPublicKey].map { (key: Data) throws -> HDWalletKit.PublicKey in
			guard let compressed = Secp256k1Utils.convertKeyToCompressed(key) else {
				throw BlockchainSdkError.failedToCreateMultisigScript
			}
			return HDWalletKit.PublicKey(uncompressedPublicKey: key, compressedPublicKey: compressed, coin: .bitcoin)
		}
		pubKeys.sort(by: { $0.compressedPublicKey.lexicographicallyPrecedes($1.compressedPublicKey) })
		return ScriptFactory.Standard.buildMultiSig(publicKeys: pubKeys, signaturesRequired: 1)
	}
}


public class BitcoinLegacyAddressService: AddressService {
    private let converter: IAddressConverter

    init(networkParams: INetwork) {
        converter = Base58AddressConverter(addressVersion: networkParams.pubKeyHash, addressScriptVersion: networkParams.scriptHash)
    }
    
    public func makeAddress(from pubkey: Data) -> BitcoinCore.LegacyAddress {
        let publicKey = PublicKey(withAccount: 0,
                                  index: 0,
                                  external: true,
                                  hdPublicKeyData: pubkey)
        
        let address = try! converter.convert(publicKey: publicKey, type: .p2pkh) as! BitcoinCore.LegacyAddress
        return address
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let address = makeAddress(from: walletPublicKey).stringValue
        
        return address
    }
    
    public func validate(_ address: String) -> Bool {
        do {
            _ = try converter.convert(address: address)
            return true
        } catch {
            return false
        }
    }
    
    public func makeMultisigAddress(from scriptHash: Data) -> BitcoinCore.LegacyAddress {
        try! converter.convert(keyHash: scriptHash, type: .p2sh) as! BitcoinCore.LegacyAddress
    }
	
	public func makeMultisigAddress(from scriptHash: Data) -> String {
		let address = makeMultisigAddress(from: scriptHash).stringValue
		
		return address
	}
}


public class BitcoinBech32AddressService: AddressService {
	private let converter: SegWitBech32AddressConverter
	
	init(networkParams: INetwork) {
		let scriptConverter = ScriptConverter()
		converter = SegWitBech32AddressConverter(prefix: networkParams.bech32PrefixPattern, scriptConverter: scriptConverter)
	}
	
    public func makeAddress(from walletPublicKey: Data) -> SegWitAddress {
        let compressedKey = Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!
        let publicKey = PublicKey(withAccount: 0,
                                  index: 0,
                                  external: true,
                                  hdPublicKeyData: compressedKey)
        
        let address = try! converter.convert(publicKey: publicKey, type: .p2wpkh) as! SegWitAddress
        
        return address
    }
    
	public func makeAddress(from walletPublicKey: Data) -> String {
		let address = makeAddress(from: walletPublicKey).stringValue
		
		return address
	}
	
	public func validate(_ address: String) -> Bool {
		do {
			_ = try converter.convert(address: address)
			return true
		} catch {
			return false
		}
	}
    
    public func makeMultisigAddress(from scriptHash: Data) -> SegWitAddress {
        try! converter.convert(scriptHash: scriptHash) as! SegWitAddress
    }
	
	public func makeMultisigAddress(from scriptHash: Data) -> String {
		print("Script hash hex: ", scriptHash.hex)
		let address = makeMultisigAddress(from: scriptHash).stringValue
		
		return address
	}
}

extension BitcoinAddressService: MultisigAddressProvider {
	public func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data) -> [Address]? {
		do {
			return try make1Of2MultisigAddresses(firstPublicKey: walletPublicKey, secondPublicKey: pairPublicKey)
		} catch {
			print(error)
			return nil
		}
	}
}
