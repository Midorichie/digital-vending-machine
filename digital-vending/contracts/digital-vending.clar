;; Enhanced Digital Vending Machine (Phase 2)
;; SPDX-License-Identifier: MIT

(define-fungible-token PRIZE-TOKEN)
(define-non-fungible-token PRIZE-NFT uint)

;; Error codes (uint)
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-NO-PRIZES u101)
(define-constant ERR-INDEX-OOB u102)
(define-constant ERR-PAUSED u103)
(define-constant ERR-INSUFFICIENT-BALANCE u104)
(define-constant ERR-INVALID-AMOUNT u105)
(define-constant ERR-PRIZE-NOT-FOUND u106)
(define-constant ERR-MAX-PRIZES-REACHED u107)

;; Admin & config
(define-data-var admin principal tx-sender)
(define-data-var treasury principal tx-sender)
(define-data-var price uint u1000000) ;; 1 STX (adjust)
(define-data-var paused bool false)

;; Prize kinds
(define-constant KIND-FT u0)
(define-constant KIND-NFT u1)

;; Prize list: up to 20 entries
(define-data-var prizes (list 20 (tuple (kind uint) (amount uint) (weight uint))) (list))
(define-data-var nft-next-id uint u1)

;; Statistics tracking
(define-data-var total-vends uint u0)
(define-data-var total-revenue uint u0)
(define-map user-vend-count principal uint)

;; Events for better tracking
(define-map vend-history uint (tuple (user principal) (prize-kind uint) (prize-amount uint) (timestamp uint)))

;; ---------- Read-only helpers ----------
(define-read-only (get-admin) 
  (ok (var-get admin)))

(define-read-only (get-treasury) 
  (ok (var-get treasury)))

(define-read-only (get-price) 
  (ok (var-get price)))

(define-read-only (is-paused) 
  (ok (var-get paused)))

(define-read-only (get-prizes) 
  (ok (var-get prizes)))

(define-read-only (get-statistics)
  (ok {
    total-vends: (var-get total-vends),
    total-revenue: (var-get total-revenue),
    prize-count: (len (var-get prizes)),
    next-nft-id: (var-get nft-next-id)
  }))

(define-read-only (get-user-vend-count (user principal))
  (default-to u0 (map-get? user-vend-count user)))

(define-read-only (get-vend-history (vend-id uint))
  (map-get? vend-history vend-id))

;; Calculate total weight for weighted random selection
(define-read-only (calculate-total-weight)
  (fold + (map get-weight (var-get prizes)) u0))

(define-private (get-weight (prize (tuple (kind uint) (amount uint) (weight uint))))
  (get weight prize))

;; ---------- Private checks ----------
(define-private (only-admin)
  (ok (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))))

;; Improved randomness using multiple block properties and user data
(define-private (generate-random-seed)
  (let (
    (base-seed (+ block-height 
                  (* burn-block-height u7)
                  (* (var-get total-vends) u11)
                  (* (var-get nft-next-id) u13)))
  )
  base-seed))

;; Helper to find prize index using fold
(define-private (find-weighted-prize-index (prizes-list (list 20 (tuple (kind uint) (amount uint) (weight uint)))) (target uint))
  (get result (fold find-prize-accumulator prizes-list { target: target, current-weight: u0, result: none, index: u0 })))

(define-private (find-prize-accumulator 
  (prize (tuple (kind uint) (amount uint) (weight uint)))
  (acc (tuple (target uint) (current-weight uint) (result (optional uint)) (index uint))))
  (if (is-some (get result acc))
    ;; Already found, just increment index
    { 
      target: (get target acc), 
      current-weight: (get current-weight acc), 
      result: (get result acc), 
      index: (+ (get index acc) u1) 
    }
    ;; Still searching
    (let ((new-weight (+ (get current-weight acc) (get weight prize))))
      (if (< (get target acc) new-weight)
        ;; Found it!
        { 
          target: (get target acc), 
          current-weight: new-weight, 
          result: (some (get index acc)), 
          index: (+ (get index acc) u1) 
        }
        ;; Keep searching
        { 
          target: (get target acc), 
          current-weight: new-weight, 
          result: none, 
          index: (+ (get index acc) u1) 
        }))))

;; ---------- Admin functions ----------
(define-public (set-admin (new-admin principal))
  (begin
    (try! (only-admin))
    (var-set admin new-admin)
    (ok true)))

(define-public (set-treasury (new-treasury principal))
  (begin
    (try! (only-admin))
    (var-set treasury new-treasury)
    (ok true)))

(define-public (set-price (new-price uint))
  (begin
    (try! (only-admin))
    (asserts! (> new-price u0) (err ERR-INVALID-AMOUNT))
    (var-set price new-price)
    (ok true)))

(define-public (pause (p bool))
  (begin
    (try! (only-admin))
    (var-set paused p)
    (ok true)))

;; Enhanced add-prize with weight system - FIXED VERSION
(define-public (add-prize (kind uint) (amount uint) (weight uint))
  (begin
    (try! (only-admin))
    (asserts! (> weight u0) (err ERR-INVALID-AMOUNT))
    (let (
      (current (var-get prizes))
      (current-len (len current))
    )
      ;; Check if we're at capacity BEFORE trying to append
      (asserts! (< current-len u20) (err ERR-MAX-PRIZES-REACHED))
      (let (
        (new-prize { kind: kind, amount: amount, weight: weight })
      )
        ;; FIXED: Use correct match syntax for optional types
        (match (as-max-len? (append current new-prize) u20)
          some-list (begin 
                      (var-set prizes some-list)
                      (ok (len some-list)))
          (err ERR-MAX-PRIZES-REACHED))))))

;; Remove prize by index
(define-public (remove-prize (index uint))
  (begin
    (try! (only-admin))
    (let (
      (current (var-get prizes))
      (current-len (len current))
    )
      (asserts! (< index current-len) (err ERR-INDEX-OOB))
      (let (
        (updated (remove-at-index current index))
      )
        (match updated
          some-list (begin (var-set prizes some-list) (ok true))
          (err ERR-INDEX-OOB))))))

(define-private (remove-at-index 
  (lst (list 20 (tuple (kind uint) (amount uint) (weight uint)))) 
  (index uint))
  (let (
    (before (unwrap! (slice? lst u0 index) none))
    (after (unwrap! (slice? lst (+ index u1) (len lst)) none))
    (combined (concat before after))
  )
  (as-max-len? combined u20)))

(define-public (clear-prizes)
  (begin
    (try! (only-admin))
    (var-set prizes (list))
    (ok true)))

;; Withdraw accumulated FT tokens
(define-public (admin-withdraw-ft (amount uint) (recipient principal))
  (begin
    (try! (only-admin))
    (ft-transfer? PRIZE-TOKEN amount (as-contract tx-sender) recipient)))

;; Emergency mint tokens for prizes
(define-public (admin-mint-ft (amount uint))
  (begin
    (try! (only-admin))
    (ft-mint? PRIZE-TOKEN amount (as-contract tx-sender))))

;; ---------- Core vending ----------
(define-public (vend)
  (begin
    (asserts! (not (var-get paused)) (err ERR-PAUSED))
    (let (
      (ps (var-get prizes))
      (n (len ps))
    )
      (asserts! (> n u0) (err ERR-NO-PRIZES))
      
      ;; Collect payment
      (try! (stx-transfer? (var-get price) tx-sender (var-get treasury)))
      
      ;; Update statistics
      (let (
        (vend-count (var-get total-vends))
        (new-count (+ vend-count u1))
      )
        (var-set total-vends new-count)
        (var-set total-revenue (+ (var-get total-revenue) (var-get price)))
        (map-set user-vend-count tx-sender (+ (get-user-vend-count tx-sender) u1))
        
        ;; Weighted random selection
        (let (
          (total-weight (calculate-total-weight))
          (random-value (mod (generate-random-seed) total-weight))
          (prize-index (find-weighted-prize-index ps random-value))
        )
          (match prize-index
            some-idx 
              (let (
                (prize (unwrap-panic (element-at? ps some-idx)))
                (prize-kind (get kind prize))
                (prize-amount (get amount prize))
              )
                ;; Record the vend in history
                (map-set vend-history new-count {
                  user: tx-sender,
                  prize-kind: prize-kind,
                  prize-amount: prize-amount,
                  timestamp: block-height
                })
                
                ;; Distribute prize
                (if (is-eq prize-kind KIND-FT)
                  (begin
                    (try! (as-contract (ft-transfer? PRIZE-TOKEN prize-amount tx-sender tx-sender)))
                    (ok { kind: KIND-FT, amount: (some prize-amount), token-id: none, vend-id: new-count }))
                  (begin
                    (let ((nid (var-get nft-next-id)))
                      (var-set nft-next-id (+ nid u1))
                      (try! (nft-mint? PRIZE-NFT nid tx-sender))
                      (ok { kind: KIND-NFT, amount: none, token-id: (some nid), vend-id: new-count })))))
            (err ERR-INDEX-OOB)))))))

;; Allow users to check their FT balance
(define-read-only (get-ft-balance (user principal))
  (ft-get-balance PRIZE-TOKEN user))

;; Allow users to check NFT ownership
(define-read-only (get-nft-owner (token-id uint))
  (nft-get-owner? PRIZE-NFT token-id))
