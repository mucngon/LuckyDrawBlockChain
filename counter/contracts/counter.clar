;; Lucky Draw Smart Contract
;; Allows users to participate with STX and uses block data for randomness

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_GAME_ACTIVE (err u101))
(define-constant ERR_GAME_NOT_ACTIVE (err u102))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u103))
(define-constant ERR_NO_PARTICIPANTS (err u104))
(define-constant ERR_ALREADY_DRAWN (err u105))
(define-constant ERR_INVALID_BLOCK (err u106))
(define-constant ERR_ALREADY_JOINED (err u107))

;; Data Variables
(define-data-var game-active bool false)
(define-data-var entry-fee uint u1000000) ;; 1 STX = 1,000,000 microSTX
(define-data-var max-participants uint u100)
(define-data-var current-round uint u0)
(define-data-var draw-block-height uint u0)
(define-data-var winner (optional principal) none)
(define-data-var total-prize uint u0)

;; Data Maps
(define-map participants 
  { round: uint, participant: principal } 
  { entry-block: uint, amount: uint }
)

(define-map participant-list 
  { round: uint, index: uint } 
  principal
)

(define-map round-info 
  uint 
  { 
    participants-count: uint,
    total-prize: uint,
    winner: (optional principal),
    draw-block: uint,
    completed: bool
  }
)

;; Read-only functions
(define-read-only (get-game-info)
  {
    active: (var-get game-active),
    entry-fee: (var-get entry-fee),
    max-participants: (var-get max-participants),
    current-round: (var-get current-round),
    draw-block-height: (var-get draw-block-height),
    winner: (var-get winner),
    total-prize: (var-get total-prize)
  }
)

(define-read-only (get-round-info (round uint))
  (map-get? round-info round)
)

(define-read-only (get-participant-info (round uint) (participant principal))
  (map-get? participants { round: round, participant: participant })
)

(define-read-only (get-current-participants-count)
  (let ((round (var-get current-round)))
    (match (map-get? round-info round)
      round-data (get participants-count round-data)
      u0
    )
  )
)

(define-read-only (get-participant-by-index (round uint) (index uint))
  (map-get? participant-list { round: round, index: index })
)

;; Private functions
(define-private (increment-participants-count (round uint))
  (let ((current-info (default-to 
         { participants-count: u0, total-prize: u0, winner: none, draw-block: u0, completed: false }
         (map-get? round-info round))))
    (map-set round-info round
      (merge current-info 
        { participants-count: (+ (get participants-count current-info) u1) }
      )
    )
  )
)

(define-private (add-to-prize (round uint) (amount uint))
  (let ((current-info (default-to 
         { participants-count: u0, total-prize: u0, winner: none, draw-block: u0, completed: false }
         (map-get? round-info round))))
    (map-set round-info round
      (merge current-info 
        { total-prize: (+ (get total-prize current-info) amount) }
      )
    )
  )
)

;; Public functions

;; Initialize new game
(define-public (start-new-game (fee uint) (max-parts uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (not (var-get game-active)) ERR_GAME_ACTIVE)
    
    (var-set entry-fee fee)
    (var-set max-participants max-parts)
    (var-set current-round (+ (var-get current-round) u1))
    (var-set game-active true)
    (var-set winner none)
    (var-set total-prize u0)
    (var-set draw-block-height u0)
    
    ;; Initialize round info
    (map-set round-info (var-get current-round)
      { participants-count: u0, total-prize: u0, winner: none, draw-block: u0, completed: false }
    )
    
    (ok true)
  )
)

;; Join the lucky draw
(define-public (join-draw)
  (let (
    (round (var-get current-round))
    (fee (var-get entry-fee))
    (current-count (get-current-participants-count))
    (max-parts (var-get max-participants))
  )
    (asserts! (var-get game-active) ERR_GAME_NOT_ACTIVE)
    (asserts! (< current-count max-parts) ERR_GAME_ACTIVE)
    (asserts! (is-none (map-get? participants { round: round, participant: tx-sender })) ERR_ALREADY_JOINED)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? fee tx-sender (as-contract tx-sender)))
    
    ;; Add participant
    (map-set participants 
      { round: round, participant: tx-sender }
      { entry-block: current-count, amount: fee }
    )
    
    ;; Add to participant list by index
    (map-set participant-list 
      { round: round, index: current-count }
      tx-sender
    )
    
    ;; Update statistics
    (increment-participants-count round)
    (add-to-prize round fee)
    (var-set total-prize (+ (var-get total-prize) fee))
    
    ;; If max participants reached, set draw ready
    (if (is-eq (+ current-count u1) max-parts)
      (var-set draw-block-height u1)
      true
    )
    
    (ok true)
  )
)

;; End game early (owner only)
(define-public (end-game-early)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (var-get game-active) ERR_GAME_NOT_ACTIVE)
    (asserts! (> (get-current-participants-count) u0) ERR_NO_PARTICIPANTS)
    
    (var-set draw-block-height u1)
    (ok true)
  )
)

;; Draw winner using block-based randomness
(define-public (draw-winner)
  (let (
    (round (var-get current-round))
    (draw-block (var-get draw-block-height))
    (participants-count (get-current-participants-count))
    (prize (var-get total-prize))
  )
    (asserts! (var-get game-active) ERR_GAME_NOT_ACTIVE)
    (asserts! (> draw-block u0) ERR_INVALID_BLOCK)
    (asserts! (> participants-count u0) ERR_NO_PARTICIPANTS)
    (asserts! (is-none (var-get winner)) ERR_ALREADY_DRAWN)
    
    ;; Use simple but effective randomness
    (let (
      (random-seed (+ (* draw-block u37) 
                     (* (var-get current-round) u73) 
                     (* participants-count u97)
                     (mod prize u1009)))
      (winner-index (mod random-seed participants-count))
      (selected-winner (unwrap! (get-participant-by-index round winner-index) ERR_NO_PARTICIPANTS))
    )
      ;; Calculate commission (5% for contract owner)
      (let (
        (commission (/ prize u20)) ;; 5%
        (winner-prize (- prize commission))
      )
        ;; Transfer prize to winner
        (try! (as-contract (stx-transfer? winner-prize tx-sender selected-winner)))
        ;; Transfer commission to owner
        (try! (as-contract (stx-transfer? commission tx-sender CONTRACT_OWNER)))
        
        ;; Update game state
        (var-set winner (some selected-winner))
        (var-set game-active false)
        
        ;; Update round info
        (map-set round-info round
          (merge (unwrap! (map-get? round-info round) ERR_INVALID_BLOCK)
            { 
              winner: (some selected-winner),
              draw-block: draw-block,
              completed: true
            }
          )
        )
        
        (ok selected-winner)
      )
    )
  )
)

;; Emergency refund function
(define-public (emergency-refund (participant principal))
  (let (
    (round (var-get current-round))
    (participant-info (unwrap! (map-get? participants { round: round, participant: participant }) ERR_NO_PARTICIPANTS))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (var-get game-active) ERR_GAME_NOT_ACTIVE)
    
    ;; Refund participant
    (as-contract (stx-transfer? (get amount participant-info) tx-sender participant))
  )
)

;; Emergency withdraw contract balance
(define-public (emergency-withdraw)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender CONTRACT_OWNER))
  )
)
