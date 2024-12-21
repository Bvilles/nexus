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
(define-constant err-invalid-input (err u106))

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

(define-map Followers
    { user: principal }
    (list 500 principal)
)

;; NFT Definition for Content
(define-non-fungible-token content-nft uint)

;; Helper Functions
(define-private (is-valid-string (s (string-utf8 1000)))
    (and (>= (len s) u1) (<= (len s) u1000))
)

;; Public Functions

;; Register new user
(define-public (register-user (username (string-utf8 50)) (bio (string-utf8 200)))
    (let ((user tx-sender))
        (asserts! (is-none (map-get? Users user)) err-user-exists)
        (asserts! (and (>= (len username) u1) (<= (len username) u50)) err-invalid-input)
        (asserts! (and (>= (len bio) u1) (<= (len bio) u200)) err-invalid-input)
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
            (asserts! (is-valid-string content) err-invalid-input)
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
    (let ((post (unwrap! (map-get? Posts post-id) err-post-not-found)))
        (let ((author (get author post))
              (current-tips (get tips-received post)))
            (begin
                (asserts! (> amount u0) err-invalid-input)
                (asserts! (is-some (map-get? Users author)) err-invalid-user)
                (try! (stx-transfer? amount tx-sender author))
                (ok (map-set Posts post-id
                    (merge post { tips-received: (+ current-tips amount) })))
            )
        )
    )
)

;; Update user profile
(define-public (update-profile (new-bio (string-utf8 200)))
    (let ((user-data (unwrap! (map-get? Users tx-sender) err-invalid-user)))
        (asserts! (and (>= (len new-bio) u1) (<= (len new-bio) u200)) err-invalid-input)
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

;; Follow a user
(define-public (follow-user (user-to-follow principal))
    (let ((current-user tx-sender)
          (current-followers (default-to (list) 
            (map-get? Followers { user: user-to-follow }))))
        (begin
            (asserts! (is-some (map-get? Users user-to-follow)) err-invalid-user)
            (asserts! (not (is-eq current-user user-to-follow)) err-invalid-input)
            (asserts! (is-none (index-of current-followers current-user)) err-invalid-input)
            (match (as-max-len? (append current-followers current-user) u500)
                updated-followers (ok (map-set Followers 
                    { user: user-to-follow }
                    updated-followers))
                err-too-many-posts)
        )
    )
)

;; Get followers for a user
(define-read-only (get-followers (user principal))
    (default-to (list) (map-get? Followers { user: user }))
)

;; Unfollow a user
(define-public (unfollow-user (user-to-unfollow principal))
    (let ((current-user tx-sender)
          (current-followers (default-to (list) 
            (map-get? Followers { user: user-to-unfollow }))))
        (begin
            (asserts! (is-some (map-get? Users user-to-unfollow)) err-invalid-user)
            (asserts! (is-some (index-of current-followers current-user)) err-invalid-input)
            (ok (map-set Followers 
                { user: user-to-unfollow }
                (filter not-current-user current-followers)))
        )
    )
)

;; Helper function for unfollow-user
(define-private (not-current-user (user principal))
    (not (is-eq user tx-sender))
)