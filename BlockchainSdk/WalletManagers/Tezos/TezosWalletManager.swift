//
//  TezosWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.10.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class TezosWalletManager: WalletManager {
    var txBuilder: TezosTransactionBuilder!
    var networkService: TezosNetworkService!
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address)
            .sink(receiveCompletion: {[unowned self]  completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
                }, receiveValue: { [unowned self] response in
                    self.updateWallet(with: response)
                    completion(.success(()))
            })
    }
    
    private func updateWallet(with response: TezosAddress) {
        txBuilder.counter = response.counter
        
        if response.balance != wallet.amounts[.coin]?.value {
            wallet.transactions = []
        }
        
        wallet.add(coinValue: response.balance)
    }
}

extension TezosWalletManager: TransactionSender {
    var allowsFeeSelection: Bool {
        false
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        guard let contents = txBuilder.buildContents(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return networkService
            .getHeader()
            .flatMap { [unowned self] header in
                return self.networkService
                    .forgeContents(headerHash: header.hash, contents: contents)
                    .map { forgeResult -> (header: TezosHeader, forgedContents: String) in
                        return (header, forgeResult)
                }
        }
        .flatMap {[unowned self] (header, forgedContents) -> AnyPublisher<(header: TezosHeader, forgedContents: String, signResponse: SignResponse), Error> in
            guard let txToSign = self.txBuilder.buildToSign(forgedContents: forgedContents) else {
                return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
            }
            
            return signer.sign(hashes: [txToSign], cardId: self.cardId)
                .map { (header, forgedContents, $0)}
                .eraseToAnyPublisher()
        }
        .flatMap {[unowned self] (header, forgedContents, signResponse) in
            self.networkService
                .checkTransaction(protocol: header.protocol, hash: header.hash, contents: contents, signature: signResponse.signature)
                .map { _ in (forgedContents, signResponse) }
                .eraseToAnyPublisher()
        }
        .flatMap {[unowned self] (forgedContents, signResponse) -> AnyPublisher<SignResponse, Error> in
            let txToSend = self.txBuilder.buildToSend(signature: signResponse.signature, forgedContents: forgedContents)
            return self.networkService
                .sendTransaction(txToSend)
                .map{[unowned self] response in
                    self.wallet.add(transaction: transaction)
                    return signResponse
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount], Error> {
        networkService
            .checkPublicKeyRevealed(address: wallet.address)
            .combineLatest(networkService.getInfo(address: destination))
            .map {[unowned self] (isPublicKeyRevealed, destinationInfo) -> [Amount] in
                self.txBuilder.isPublicKeyRevealed = isPublicKeyRevealed
                var fee = TezosFee.transaction.rawValue
                if !isPublicKeyRevealed {
                    fee += TezosFee.reveal.rawValue
                }
                
                if destinationInfo.balance == 0 {
                    fee += TezosFee.allocation.rawValue
                }
                
                return [Amount(with: self.wallet.blockchain, value: fee)]
        }
        .eraseToAnyPublisher()
    }
}


extension TezosWalletManager: ThenProcessable { }


extension TezosWalletManager: WithdrawalValidator {
    func validate(_ transaction: Transaction) -> WithdrawalWarning? {
        guard let walletAmount = wallet.amounts[.coin] else {
            return nil
        }
        
        let minimumAmount: Decimal = 0.000001
        
        if transaction.amount + transaction.fee == walletAmount {
            return WithdrawalWarning(warningMessage: String(format: "xtz_withdrawal_message_warning".localized, minimumAmount.description),
                                     reduceMessage: String(format: "xtz_withdrawal_message_reduce".localized, minimumAmount.description),
                                     ignoreMessage: "xtz_withdrawal_message_ignore".localized,
                                     suggestedReduceAmount: Amount(with: walletAmount, value: minimumAmount))
        }
        return nil
    }
}
