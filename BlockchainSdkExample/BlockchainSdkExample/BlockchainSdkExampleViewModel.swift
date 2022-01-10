//
//  BlockchainSdkExampleViewModel.swift
//  BlockchainSdkExample
//
//  Created by Andy on 24.12.2021.
//

import Foundation
import BlockchainSdk
import TangemSdk
import Solana

class BlockchainSdkExampleViewModel: ObservableObject {
    private var account_24MT_6tAG: Account? {
        nil
    }

    private var account_EwTx_F1TY: Account? {
        nil
    }

    private var account_9C6z_zYgM: Account? {
        nil
    }

    private let accountStorage = InMemoryAccountStorage()
    private let network = NetworkingRouter(endpoint: .devnetSolana)
    private let solana: Solana

    let sdk = TangemSdk()
    @Published var card: Card?
    
    func scan() {
        sdk.scanCard(initialMessage: nil) {
            switch $0 {
            case .success(let card):
                self.card = card
            case .failure(let error):
                print(error)
            }
        }
    }


    func sign() {
        let data = Data(hex: "010001030fb791a88e9a6d1b34ff8a8757bec411b12766356eb8f11cdf23de3f54c6733dcf1bc5244ae5a5ed3bd26ec4577d531e3ead954c2f389a5b09487890ef280e230000000000000000000000000000000000000000000000000000000000000000096aa944daacaa36f8a7f984e0c152d52e1fb38a0fbdaba5156c0803c59c3b8b01020200010c020000000100000000000000")
        guard let card = card else { return }

        let publicKey = card.wallets.last!.publicKey
        print("Card public key:")
        print(publicKey)

        let address = address(publicKey)
        print("Card address:")
        print(address)

        sdk.sign(hash: data, walletPublicKey: card.wallets.last!.publicKey, cardId: card.cardId, derivationPath: nil, initialMessage: nil) {
            switch $0 {
            case .success(let x):
                print(x)
            case .failure(let error):
                print(error)
            }
        }
    }



//    let sdk = TangemSdk()

    public init() {
        self.solana = Solana(router: network, accountStorage: self.accountStorage)

//        test()

        DispatchQueue.main.asyncAfter(deadline: .now()) {

        }
    }

    public func address(_ data: Data) -> String {
        let bytes = [UInt8](data)
        return Base58.encode(bytes)
    }
    
    public func tokenTest() {
    }
    
    public func test(reverse: Bool = false) {

        print("")
        print("")
        print("")
        print("")
        print("")

        print("Addresses:")
        print([account_24MT_6tAG, account_EwTx_F1TY, account_9C6z_zYgM].compactMap { $0?.address })

        let g = DispatchGroup()
//
//        g.enter()
//        solana.api.getFees(commitment: nil) {
//            print("Get fees", $0)
//            g.leave()
//        }
//        g.wait()
//
//        g.enter()
//        solana.api.getFeeRateGovernor {
//            print("Get fee rate governor", $0)
//            g.leave()
//        }
//        g.wait()


        var accounts: [Account] = []
        if let a = account_24MT_6tAG {
            accounts.append(a)
        }
        if let a = account_EwTx_F1TY {
            accounts.append(a)
        }
        if reverse {
            accounts.reverse()
        }

//
//
//        for account in accounts {
//            print("")
//            print(account.address)
//
//            g.enter()
//            solana.api.getAccountInfo(account: account.address, decodedTo: AccountInfo.self) {
//                print("Get account info", $0)
//                g.leave()
//            }
//            g.wait()
//
//            g.enter()
//            solana.api.getBalance(account: account.address) {
//                print("Get balance", $0)
//                g.leave()
//            }
//            g.wait()
//        }
//
//
//        print("")

//        let source: Account = accounts[0]
//        let recipient: Account = accounts[1]

//        let _ = solana.auth.save(source)


//        print("Source address:", source.address)
//        print("Recipient address:", recipient.address)

        g.enter()
        solana.action.sendSOL(to: "EwTxJNhFCCYEBF1ffCrSkf6x61rT2Z1ZwpxQPwkSF1TY", amount: 1, signer: self) {
            print("Sent SOL", $0)
            g.leave()
        }
//        g.wait()

        //        g.wait()
        //        g.enter()
        //        solana.action.createTokenAccount(mintAddress: "address") {
        //            print("Create token address", $0)
        //            g.leave()
        //        }
        //


//        g.enter()
//        solana.action.createTokenAccount(mintAddress: address) {
//            print("Create token account", $0)
//            g.leave()
//        }
//
//        solana.action.getCreatingTokenAccountFee {
//            print("Get creating token account fee", $0)
//            g.leave()
//        }


//        g.wait()
//        g.enter()
//        solana.api.getTransactionCount {
//            print("Transaction count", $0)
//            g.leave()
//        }

//        let signers = [account]
//        let instructions: [TransactionInstruction] = [
//
//        ]
//
//        solana.action.serializeAndSendWithFeeSimulation(instructions: instructions, signers: signers) {
//            print("Serialize and send with fee simulation", $0)
//            g.leave()
//        }

//        solana.fee

    }

}

extension BlockchainSdkExampleViewModel: Signer {
    var edWallet: Card.Wallet? {
        card?.wallets.first(where: { w in
            w.curve == .ed25519
        })
    }
    var publicKey: PublicKey {
        .init(data: edWallet!.publicKey)!
//        .init(string: "ec7710e961a3b5477ba559baca93c1d7")!
    }
    
    func sign(message: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        let card = card!
        let wallet = edWallet!
        sdk.sign(hash: message, walletPublicKey: wallet.publicKey, cardId: card.cardId) {
            print($0)
            switch $0 {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                completion(.success(response.signature))
            }
        }
    }
}


enum SolanaAccountStorageError: Error {
    case unauthorized
}


class InMemoryAccountStorage: SolanaAccountStorage {

    private var _account: Account?
    func save(_ account: Account) -> Result<Void, Error> {
        _account = account
        return .success(())
    }
    var account: Result<Account, Error> {
        if let account = _account {
            return .success(account)
        }
        return .failure(SolanaAccountStorageError.unauthorized)
    }
    func clear() -> Result<Void, Error> {
        _account = nil
        return .success(())
    }
}

extension Account {
    var address: String {
        self.publicKey.base58EncodedString
    }
}
