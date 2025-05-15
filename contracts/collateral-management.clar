;; Collateral Management Contract
;; Tracks assets backing the currency

(define-map collateral-balances
  { asset: (string-ascii 32), owner: principal }
  { amount: uint })

(define-map supported-assets (string-ascii 32) bool)

;; Initialize supported assets
(define-data-var total-collateral-value uint u0)

;; Add a supported asset
(define-public (add-supported-asset (asset (string-ascii 32)))
  (begin
    (asserts! (is-eq tx-sender (contract-owner)) (err u100))
    (ok (map-set supported-assets asset true))))

;; Check if asset is supported
(define-read-only (is-asset-supported (asset (string-ascii 32)))
  (default-to false (map-get? supported-assets asset)))

;; Deposit collateral
(define-public (deposit-collateral (asset (string-ascii 32)) (amount uint))
  (let ((current-balance (default-to { amount: u0 }
                          (map-get? collateral-balances { asset: asset, owner: tx-sender }))))
    (asserts! (is-asset-supported asset) (err u1))
    (asserts! (> amount u0) (err u2))

    ;; Update collateral balance
    (map-set collateral-balances
      { asset: asset, owner: tx-sender }
      { amount: (+ (get amount current-balance) amount) })

    ;; Update total collateral value (simplified, should use price oracle in real implementation)
    (var-set total-collateral-value (+ (var-get total-collateral-value) amount))
    (ok true)))

;; Withdraw collateral
(define-public (withdraw-collateral (asset (string-ascii 32)) (amount uint))
  (let ((current-balance (default-to { amount: u0 }
                          (map-get? collateral-balances { asset: asset, owner: tx-sender }))))
    (asserts! (>= (get amount current-balance) amount) (err u3))

    ;; Update collateral balance
    (map-set collateral-balances
      { asset: asset, owner: tx-sender }
      { amount: (- (get amount current-balance) amount) })

    ;; Update total collateral value
    (var-set total-collateral-value (- (var-get total-collateral-value) amount))
    (ok true)))

;; Get collateral balance
(define-read-only (get-collateral-balance (asset (string-ascii 32)) (owner principal))
  (default-to { amount: u0 }
    (map-get? collateral-balances { asset: asset, owner: owner })))

;; Get total collateral value
(define-read-only (get-total-collateral-value)
  (var-get total-collateral-value))

;; Get the contract owner
(define-read-only (contract-owner)
  (as-contract tx-sender))
