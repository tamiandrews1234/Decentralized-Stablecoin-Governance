;; Validator Verification Contract
;; Validates governance participants

(define-data-var min-stake uint u10000)
(define-map validators principal uint)

;; Register as a validator with a stake
(define-public (register-validator (stake uint))
  (let ((current-stake (default-to u0 (map-get? validators tx-sender))))
    (asserts! (>= stake (var-get min-stake)) (err u1))
    (ok (map-set validators tx-sender stake))))

;; Check if an address is a validator
(define-read-only (is-validator (address principal))
  (is-some (map-get? validators address)))

;; Get validator stake
(define-read-only (get-validator-stake (address principal))
  (default-to u0 (map-get? validators address)))

;; Update minimum stake requirement (admin only)
(define-public (update-min-stake (new-min-stake uint))
  (begin
    (asserts! (is-eq tx-sender (contract-owner)) (err u100))
    (ok (var-set min-stake new-min-stake))))

;; Get the contract owner
(define-read-only (contract-owner)
  (as-contract tx-sender))
