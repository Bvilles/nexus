;; Nexus - Decentralized Social Media Platform
;; Author: Your Name
;; License: MIT

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-invalid-user (err u102))
(define-constant err-post-not-found (err u103))
(define-constant err-user-exists (err u104))
(define-constant err-too-many-posts (err u105))

;; Data Variables
(define-data-var post-counter uint u0)

;; Data Maps
(define-map Users 
    principal 
    { username: (string-utf8 50),
      bio: (string-utf8 200),
      joined-at: uint }
)

(define-map Posts 
    uint 
    { author: principal,
      content: (string-utf8 1000),
      timestamp: uint,
      tips-received: uint }
)

(define-map UserPosts
    principal
    (list 50 uint)
)

;; NFT Definition for Content
(define-non-fungible-token content-nft uint)

;; Public Functions

;; Register new user
(define-public (register-user (username (string-utf8 50)) (bio (string-utf8 200)))
    (let ((user tx-sender))
        (asserts! (is-none (map-get? Users user)) err-user-exists)
        (ok (map-set Users 
            user 
            { username: username,
              bio: bio,
              joined-at: block-height }))
    )
)

;; Create new post
(define-public (create-post (content (string-utf8 1000)))
    (let ((post-id (+ (var-get post-counter) u1))
          (user tx-sender)
          (existing-posts (default-to (list) (map-get? UserPosts user))))
        (begin
            (asserts! (< (len existing-posts) u50) err-too-many-posts)
            (try! (nft-mint? content-nft post-id user))
            (map-set Posts post-id
                { author: user,
                  content: content,
                  timestamp: block-height,
                  tips-received: u0 })
            (var-set post-counter post-id)
            (match (as-max-len? (append existing-posts post-id) u50)
                updated-list (ok (map-set UserPosts user updated-list))
                err-too-many-posts)
        )
    )
)

;; Tip a post
(define-public (tip-post (post-id uint) (amount uint))
    (let ((post (unwrap! (map-get? Posts post-id) err-post-not-found))
          (author (get author post)))
        (begin
            (try! (stx-transfer? amount tx-sender author))
            (map-set Posts post-id
                (merge post { tips-received: (+ (get tips-received post) amount) }))
            (ok true)
        )
    )
)

;; Update user profile
(define-public (update-profile (new-bio (string-utf8 200)))
    (let ((user-data (unwrap! (map-get? Users tx-sender) err-invalid-user)))
        (ok (map-set Users
            tx-sender
            (merge user-data { bio: new-bio })))
    )
)

;; Read-only functions

;; Get user profile
(define-read-only (get-user-profile (user principal))
    (map-get? Users user)
)

;; Get post details
(define-read-only (get-post (post-id uint))
    (map-get? Posts post-id)
)

;; Get user's posts
(define-read-only (get-user-posts (user principal))
    (map-get? UserPosts user)
)