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
(define-data-var comment-counter uint u0)

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

(define-map Comments
    uint 
    { post-id: uint,
      author: principal,
      content: (string-utf8 500),
      timestamp: uint }
)

(define-map UserPosts
    principal
    (list 50 uint)
)

(define-map Followers
    { user: principal, follower: principal }
    bool
)

(define-map FollowerCounts
    principal
    uint
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

;; Follow a user
(define-public (follow-user (user principal))
    (let ((follower tx-sender)
          (current-count (get-follower-count user)))
        (begin
            (asserts! (not (is-eq user follower)) err-invalid-input)
            (asserts! (is-some (map-get? Users user)) err-invalid-user)
            (map-set Followers
                { user: user, follower: follower }
                true)
            (map-set FollowerCounts
                user
                (+ current-count u1))
            (ok true)
        )
    )
)

;; Unfollow a user
(define-public (unfollow-user (user principal))
    (let ((follower tx-sender)
          (current-count (get-follower-count user)))
        (begin
            (asserts! (not (is-eq user follower)) err-invalid-input)
            (asserts! (is-some (map-get? Users user)) err-invalid-user)
            (asserts! (is-following user follower) err-invalid-input)
            (map-set Followers
                { user: user, follower: follower }
                false)
            (map-set FollowerCounts
                user
                (- current-count u1))
            (ok true)
        )
    )
)

;; Add comment to a post
(define-public (add-comment (post-id uint) (content (string-utf8 500)))
    (let ((comment-id (+ (var-get comment-counter) u1)))
        (begin
            (asserts! (is-some (map-get? Posts post-id)) err-post-not-found)
            (asserts! (and (>= (len content) u1) (<= (len content) u500)) err-invalid-input)
            (map-set Comments
                comment-id
                { post-id: post-id,
                  author: tx-sender,
                  content: content,
                  timestamp: block-height })
            (var-set comment-counter comment-id)
            (ok comment-id)
        )
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

;; Get follower count for a user
(define-read-only (get-follower-count (user principal))
    (default-to u0 (map-get? FollowerCounts user))
)

;; Check if one user follows another
(define-read-only (is-following (user principal) (follower principal))
    (default-to false (map-get? Followers { user: user, follower: follower }))
)

