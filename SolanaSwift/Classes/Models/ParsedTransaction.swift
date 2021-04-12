//
//  ParsedTransaction.swift
//  SolanaSwift
//
//  Created by Chung Tran on 05/04/2021.
//

import Foundation

public extension SolanaSDK {
    struct AnyTransaction: Hashable {
        public init(signature: String?, value: AnyHashable?, amountInFiat: Double? = nil, slot: UInt64?, blockTime: Date?) {
            self.signature = signature
            self.value = value
            self.amountInFiat = amountInFiat
            self.slot = slot
            self.blockTime = blockTime
        }
        
        public let signature: String?
        public let value: AnyHashable?
        public var amountInFiat: Double?
        public let slot: UInt64?
        public let blockTime: Date?
        
        public var amount: Double {
            switch value {
            case let transaction as CreateAccountTransaction:
                return -(transaction.fee ?? 0)
            case let transaction as CloseAccountTransaction:
                return transaction.reimbursedAmount ?? 0
            case let transaction as TransferTransaction:
                var amount = transaction.amount ?? 0
                if transaction.transferType == .send {
                    amount = -amount
                }
                return amount
            case let transaction as SwapTransaction:
                var amount = 0.0
                switch transaction.direction {
                case .spend:
                    amount = -(transaction.sourceAmount ?? 0)
                case .receive:
                    amount = transaction.destinationAmount ?? 0
                default:
                    break
                }
                return amount
            default:
                return 0
            }
        }
        
        public var symbol: String {
            switch value {
            case is CreateAccountTransaction, is CloseAccountTransaction:
                return "SOL"
            case let transaction as TransferTransaction:
                return transaction.source?.symbol ?? transaction.destination?.symbol ?? ""
            case let transaction as SwapTransaction:
                switch transaction.direction {
                case .spend:
                    return transaction.source?.symbol ?? ""
                case .receive:
                    return transaction.destination?.symbol ?? ""
                default:
                    return ""
                }
            default:
                return ""
            }
        }
    }
    
    struct CreateAccountTransaction: Hashable {
        public let fee: Double? // in SOL
        public let newToken: Token?
        
        static var empty: Self {
            CreateAccountTransaction(fee: nil, newToken: nil)
        }
    }
    
    struct CloseAccountTransaction: Hashable {
        public let reimbursedAmount: Double?
        public let closedToken: Token?
    }
    
    struct TransferTransaction: Hashable {
        public enum TransferType {
            case send, receive
        }
        
        public let source: Token?
        public let destination: Token?
        public let amount: Double?
        
        let myAccount: String?
        
        public var transferType: TransferType? {
            if source?.pubkey == myAccount {
                return .send
            }
            if destination?.pubkey == myAccount {
                return .receive
            }
            return nil
        }
    }
    
    struct SwapTransaction: Hashable {
        public enum Direction {
            case spend, receive
        }
        
        // source
        public let source: Token?
        public let sourceAmount: Double?
        
        // destination
        public let destination: Token?
        public let destinationAmount: Double?
        
        let myAccountSymbol: String?
        
        static var empty: Self {
            SwapTransaction(source: nil, sourceAmount: nil, destination: nil, destinationAmount: nil, myAccountSymbol: nil)
        }
        
        public var direction: Direction? {
            if myAccountSymbol == source?.symbol {
                return .spend
            }
            if myAccountSymbol == destination?.symbol {
                return .receive
            }
            return nil
        }
    }
}