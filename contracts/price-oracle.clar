;; Price Oracle Contract
;; Records external asset values

(define-map asset-prices (string-ascii 32) { price: uint, last-updated: uint })
(define-map price-providers principal bool)

;; Initialize price providers
(define-data-var min-providers uint u3)
(define-data-var price-validity-period uint u86400) ;; 24 hours in seconds

;; Add a price provider
(define-public (add-price-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender (contract-owner)) (err u100))
    (ok (map-set price-providers provider true))))

;; Check if address is a price provider
(define-read-only (is-price-provider (address principal))
  (default-to false (map-get? price-providers address)))

;; Update asset price
(define-public (update-price (asset (string-ascii 32)) (price uint))
  (begin
    (asserts! (is-price-provider tx-sender) (err u1))
    (ok (map-set asset-prices asset {
      price: price,
      last-updated: block-height
    }))))

;; Get asset price
(define-read-only (get-asset-price (asset (string-ascii 32)))
  (let ((price-data (map-get? asset-prices asset)))
    (asserts! (is-some price-data) (err u2))
    (let ((unwrapped-data (unwrap! price-data (err u3))))
      (asserts! (< (- block-height (get last-updated unwrapped-data))
                  (var-get price-validity-period))
                (err u4))
      (ok (get price unwrapped-data)))))

;; Update price validity period
(define-public (update-validity-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (contract-owner)) (err u100))
    (ok (var-set price-validity-period new-period))))

;; Get the contract owner
(define-read-only (contract-owner)
  (as-contract tx-sender))
