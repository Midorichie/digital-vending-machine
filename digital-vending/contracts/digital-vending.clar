;; Digital Vending Machine (demo)
;; SPDX-License-Identifier: MIT

(define-fungible-token PRIZE-TOKEN)
(define-non-fungible-token PRIZE-NFT uint)

;; Error codes (uint)
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-NO-PRIZES u101)
(define-constant ERR-INDEX-OOB u102)
(define-constant ERR-PAUSED u103)

;; Admin & config
(define-data-var admin principal tx-sender)
(define-data-var treasury principal tx-sender)
(define-data-var price uint u1000000) ;; 1 STX (adjust)
(define-data-var paused bool false)

;; Prize kinds
(define-constant KIND-FT u0)
(define-constant KIND-NFT u1)

;; Prize list: up to 20 entries
(define-data-var prizes (list 20 (tuple (kind uint) (amount uint))) (list))
(define-data-var nft-next-id uint u1)

;; ---------- Read-only helpers ----------
(define-read-only (get-admin) (ok (var-get admin)))
(define-read-only (get-treasury) (ok (var-get treasury)))
(define-read-only (get-price) (ok (var-get price)))
(define-read-only (is-paused) (ok (var-get paused)))
(define-read-only (get-prizes) (ok (var-get prizes)))

;; ---------- Private checks ----------
(define-private (only-admin)
  (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED))

;; ---------- Admin functions ----------
(define-public (set-admin (new-admin principal))
  (begin
    (unwrap! (only-admin) ERR-NOT-AUTHORIZED)
    (var-set admin new-admin)
    (ok true)))

(define-public (set-treasury (new-treasury principal))
  (begin
    (unwrap! (only-admin) ERR-NOT-AUTHORIZED)
    (var-set treasury new-treasury)
    (ok true)))

(define-public (set-price (new-price uint))
  (begin
    (unwrap! (only-admin) ERR-NOT-AUTHORIZED)
    (var-set price new-price)
    (ok true)))

(define-public (pause (p bool))
  (begin
    (unwrap! (only-admin) ERR-NOT-AUTHORIZED)
    (var-set paused p)
    (ok true)))

(define-public (add-prize (kind uint) (amount uint))
  (begin
    (unwrap! (only-admin) ERR-NOT-AUTHORIZED)
    (let
      (
        (current (var-get prizes))
        (new-prize { kind: kind, amount: amount })
        (updated (append current new-prize))
      )
      (asserts! (<= (len updated) u20) u999)
      (var-set prizes updated)
      (ok (len updated)))))

(define-public (clear-prizes)
  (begin
    (unwrap! (only-admin) ERR-NOT-AUTHORIZED)
    (var-set prizes (list))
    (ok true)))

;; ---------- Core vending ----------
(define-public (vend)
  (begin
    (asserts! (not (var-get paused)) ERR-PAUSED)
    (let
      (
        (ps (var-get prizes))
        (n (len ps))
      )
      (asserts! (> n u0) ERR-NO-PRIZES)
      ;; collect payment
      (unwrap! (stx-transfer? (var-get price) tx-sender (var-get treasury)) u110)
      ;; naive selection: idx = block-height mod n
      (let
        (
          (idx (mod block-height n))
          (maybe (element-at? ps idx))
        )
        (match maybe prize
          (if (is-eq (get kind prize) KIND-FT)
            (begin
              (unwrap! (ft-mint? PRIZE-TOKEN (get amount prize) tx-sender) u120)
              (ok { kind: KIND-FT, amount: (get amount prize) })
            )
            (begin
              (let ((nid (var-get nft-next-id)))
                (var-set nft-next-id (+ nid u1))
                (unwrap! (nft-mint? PRIZE-NFT nid tx-sender) u121)
                (ok { kind: KIND-NFT, token-id: nid })
              )
            )
          )
          (err ERR-INDEX-OOB)
        )
      )
    )
  ))
