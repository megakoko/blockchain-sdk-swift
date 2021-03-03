//
//  StellarWalletmanager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import SwiftyJSON
import Combine
import TangemSdk

public enum StellarError: String, Error, LocalizedError {
    case emptyResponse = "xlm_empty_response_error"
    case requiresMemo = "xlm_requires_memo_error"
    case failedToFindLatestLedger = "xlm_latest_ledger_error"
    case xlmCreateAccount = "no_account_xlm"
    case assetCreateAccount = "no_account_xlm_asset"
    case assetNoAccountOnDestination = "no_account_on_destination_xlm_asset"
    case assetNoTrustline = "no_trustline_xlm_asset"
    
    public var errorDescription: String? {
        return self.rawValue.localized
    }
}

class StellarWalletManager: WalletManager {
    var txBuilder: StellarTransactionBuilder!
    var networkService: StellarNetworkService!
    var stellarSdk: StellarSDK!
    private var baseFee: Decimal?
    
    override func update(completion: @escaping (Result<(), Error>)-> Void)  {
        cancellable = networkService
            .getInfo(accountId: wallet.address, isAsset: !cardTokens.isEmpty)
            .sink(receiveCompletion: {[unowned self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    private func updateWallet(with response: StellarResponse) {
        txBuilder.sequence = response.sequence
        self.baseFee = response.baseFee
        let fullReserve = response.assetBalances.isEmpty ? response.baseReserve * 2 : response.baseReserve * 3
        wallet.add(reserveValue: fullReserve)
        wallet.add(coinValue: response.balance - fullReserve)
        
        if cardTokens.isEmpty {
            _ = response.assetBalances
                .map { (Token(symbol: $0.code,
                              contractAddress: $0.issuer,
                              decimalCount: wallet.blockchain.decimalCount),
                        $0.balance) }
                .map { token, balance in
                    wallet.add(tokenValue: balance, for: token)
            }
        } else {
            for token in cardTokens {
                let assetBalance = response.assetBalances.first(where: { $0.code == token.symbol })?.balance ?? 0.0
                wallet.add(tokenValue: assetBalance, for: token)
                
            }
        }
        let currentDate = Date()
        for  index in wallet.transactions.indices {
            if DateInterval(start: wallet.transactions[index].date!, end: currentDate).duration > 10 {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
}

extension StellarWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        return txBuilder.buildForSign(transaction: transaction)
            .flatMap { [unowned self] buildForSignResponse in
                signer.sign(hashes: [buildForSignResponse.hash], cardId: self.cardId)
                    .map { return ($0, buildForSignResponse) }.eraseToAnyPublisher()
        }
        .tryMap {[unowned self] result throws -> (String,SignResponse) in
            guard let tx = self.txBuilder.buildForSend(signature: result.0.signature, transaction: result.1.transaction) else {
                throw WalletError.failedToBuildTx
            }
            
            return (tx, result.0)
        }
        .flatMap {[unowned self] values -> AnyPublisher<SignResponse, Error> in
            self.networkService.send(transaction: values.0).map {[unowned self] sendResponse in
                 self.wallet.add(transaction: transaction)
                return values.1
            } .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount], Error> {
        if let feeValue = self.baseFee {
            let feeAmount = Amount(with: wallet.blockchain, value: feeValue)
            return Result.Publisher([feeAmount]).eraseToAnyPublisher()
        } else {
            return Fail(error: WalletError.failedToGetFee).eraseToAnyPublisher()
        }
    }
}

extension StellarWalletManager: SignatureCountValidator {
	func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
		networkService.getSignatureCount(accountId: wallet.address)
			.tryMap {
				if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
			}
			.eraseToAnyPublisher()
	}
}

extension StellarWalletManager: ThenProcessable { }
