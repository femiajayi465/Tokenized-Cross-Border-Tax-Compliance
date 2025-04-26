;; Entity Verification Contract
;; Validates international businesses for tax compliance

(define-data-var admin principal tx-sender)

;; Entity status: 0 = unverified, 1 = pending, 2 = verified, 3 = rejected
(define-map entities
  { entity-id: (string-utf8 36) }
  {
    owner: principal,
    name: (string-utf8 100),
    country: (string-utf8 2),
    tax-id: (string-utf8 50),
    status: uint,
    verification-date: uint
  }
)

(define-read-only (get-entity (entity-id (string-utf8 36)))
  (map-get? entities { entity-id: entity-id })
)

(define-public (register-entity
    (entity-id (string-utf8 36))
    (name (string-utf8 100))
    (country (string-utf8 2))
    (tax-id (string-utf8 50)))
  (let ((existing-entity (get-entity entity-id)))
    (asserts! (is-none existing-entity) (err u1)) ;; Entity already exists
    (ok (map-set entities
      { entity-id: entity-id }
      {
        owner: tx-sender,
        name: name,
        country: country,
        tax-id: tax-id,
        status: u1, ;; Set to pending
        verification-date: u0
      }
    ))
  )
)

(define-public (verify-entity (entity-id (string-utf8 36)))
  (let ((entity (unwrap! (get-entity entity-id) (err u2)))) ;; Entity not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (asserts! (is-eq (get status entity) u1) (err u4)) ;; Not in pending status
    (ok (map-set entities
      { entity-id: entity-id }
      (merge entity {
        status: u2, ;; Set to verified
        verification-date: block-height
      })
    ))
  )
)

(define-public (reject-entity (entity-id (string-utf8 36)))
  (let ((entity (unwrap! (get-entity entity-id) (err u2)))) ;; Entity not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (asserts! (is-eq (get status entity) u1) (err u4)) ;; Not in pending status
    (ok (map-set entities
      { entity-id: entity-id }
      (merge entity {
        status: u3, ;; Set to rejected
        verification-date: block-height
      })
    ))
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)

(define-read-only (is-verified-entity (entity-id (string-utf8 36)))
  (let ((entity (get-entity entity-id)))
    (if (is-some entity)
      (is-eq (get status (unwrap-panic entity)) u2) ;; Check if status is verified
      false
    )
  )
)
