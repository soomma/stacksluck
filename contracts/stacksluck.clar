;; StacksLuck - Decentralized Lottery Pool Smart Contract
;; A fair and transparent lottery system on the Stacks blockchain

;; Constants
(define-constant PROTOCOL_ADMIN tx-sender)
(define-constant ERR_UNAUTHORIZED_ACCESS (err u100))
(define-constant ERR_GAME_NOT_RUNNING (err u102))
(define-constant ERR_WALLET_BALANCE_LOW (err u103))
(define-constant ERR_ENTRY_FEE_INVALID (err u104))
(define-constant ERR_CHAMPION_COUNT_ZERO (err u105))
(define-constant ERR_NO_ENTRIES_FOUND (err u106))
(define-constant ERR_REFUND_WINDOW_CLOSED (err u107))
(define-constant ERR_GAME_STILL_ACTIVE (err u108))
(define-constant ERR_CHAMPIONS_ALREADY_CHOSEN (err u109))
(define-constant ERR_GAME_DURATION_INVALID (err u110))
(define-constant ERR_REFUND_WINDOW_INVALID (err u111))
(define-constant ERR_CHAMPION_ID_INVALID (err u112))
(define-constant ERR_GAME_ALREADY_STARTED (err u113))

;; Data Variables
(define-data-var game-status bool false)
(define-data-var entry-fee-amount uint u1000000) ;; 1 STX default
(define-data-var prize-pool-total uint u0)
(define-data-var entries-count uint u0)
(define-data-var champions-to-select uint u1)
(define-data-var game-deadline-block uint u0)
(define-data-var refund-deadline-block uint u0)
(define-data-var admin-commission-rate uint u5) ;; 5% commission
(define-data-var individual-champion-prize uint u0)
(define-data-var champions-selection-complete bool false)
(define-data-var game-rounds-played uint u0)

;; Maps
(define-map entry-records {entry-id: uint} {participant: principal})
(define-map participant-entries principal uint)
(define-map champion-registry {champion-id: uint} {winner: principal, prize-claimed: bool})
(define-map game-statistics {round: uint} {total-entries: uint, prize-amount: uint, champions-count: uint})

;; Private Functions
(define-private (verify-admin-privileges)
  (is-eq tx-sender PROTOCOL_ADMIN))

(define-private (ensure-game-is-active)
  (if (var-get game-status)
    (ok true)
    ERR_GAME_NOT_RUNNING))

(define-private (validate-wallet-balance (required-amount uint))
  (if (>= (stx-get-balance tx-sender) required-amount)
    (ok true)
    ERR_WALLET_BALANCE_LOW))

(define-private (generate-random-winner (seed uint) (entry-offset uint))
  (mod (+ seed entry-offset) (var-get entries-count)))

(define-private (send-prize-to-champion (champion-address principal) (prize-value uint))
  (as-contract (stx-transfer? prize-value tx-sender champion-address)))

(define-private (calculate-admin-fee (total-pool uint))
  (/ (* total-pool (var-get admin-commission-rate)) u100))

;; Public Functions
(define-public (initialize-new-game (duration-blocks uint) (refund-window-blocks uint) (ticket-cost uint) (winner-slots uint) (commission-percent uint))
  (begin
    (asserts! (verify-admin-privileges) ERR_UNAUTHORIZED_ACCESS)
    (asserts! (> ticket-cost u0) ERR_ENTRY_FEE_INVALID)
    (asserts! (> winner-slots u0) ERR_CHAMPION_COUNT_ZERO)
    (asserts! (<= commission-percent u20) ERR_UNAUTHORIZED_ACCESS) ;; Max 20% commission
    (asserts! (not (var-get game-status)) ERR_GAME_ALREADY_STARTED)
    (asserts! (> duration-blocks u0) ERR_GAME_DURATION_INVALID)
    (asserts! (> refund-window-blocks u0) ERR_REFUND_WINDOW_INVALID)
    (var-set game-status true)
    (var-set entry-fee-amount ticket-cost)
    (var-set prize-pool-total u0)
    (var-set entries-count u0)
    (var-set champions-to-select winner-slots)
    (var-set game-deadline-block (+ block-height duration-blocks))
    (var-set refund-deadline-block (+ block-height refund-window-blocks))
    (var-set admin-commission-rate commission-percent)
    (var-set champions-selection-complete false)
    (ok true)))

(define-public (buy-game-entry)
  (let ((ticket-cost (var-get entry-fee-amount)))
    (begin
      (try! (ensure-game-is-active))
      (try! (validate-wallet-balance ticket-cost))
      (try! (stx-transfer? ticket-cost tx-sender (as-contract tx-sender)))
      (var-set prize-pool-total (+ (var-get prize-pool-total) ticket-cost))
      (var-set entries-count (+ (var-get entries-count) u1))
      (map-set entry-records {entry-id: (var-get entries-count)} {participant: tx-sender})
      (map-set participant-entries tx-sender (+ (default-to u0 (map-get? participant-entries tx-sender)) u1))
      (ok (var-get entries-count)))))

(define-public (request-entry-refund (entries-to-refund uint))
  (let ((user-entry-count (default-to u0 (map-get? participant-entries tx-sender)))
        (refund-total (* entries-to-refund (var-get entry-fee-amount))))
    (begin
      (try! (ensure-game-is-active))
      (asserts! (<= block-height (var-get refund-deadline-block)) ERR_REFUND_WINDOW_CLOSED)
      (asserts! (>= user-entry-count entries-to-refund) ERR_NO_ENTRIES_FOUND)
      (var-set prize-pool-total (- (var-get prize-pool-total) refund-total))
      (var-set entries-count (- (var-get entries-count) entries-to-refund))
      (map-set participant-entries tx-sender (- user-entry-count entries-to-refund))
      (as-contract (stx-transfer? refund-total tx-sender tx-sender)))))

(define-public (finalize-current-game)
  (let ((total-pool (var-get prize-pool-total))
        (winner-count (var-get champions-to-select))
        (total-entries (var-get entries-count))
        (admin-fee (calculate-admin-fee total-pool))
        (current-round (+ (var-get game-rounds-played) u1)))
    (begin
      (asserts! (verify-admin-privileges) ERR_UNAUTHORIZED_ACCESS)
      (asserts! (>= block-height (var-get game-deadline-block)) ERR_GAME_STILL_ACTIVE)
      (try! (ensure-game-is-active))
      (asserts! (> total-entries u0) ERR_CHAMPION_COUNT_ZERO)
      (var-set game-status false)
      (try! (as-contract (stx-transfer? admin-fee tx-sender PROTOCOL_ADMIN)))
      (let ((remaining-prize-pool (- total-pool admin-fee)))
        (var-set individual-champion-prize (/ remaining-prize-pool winner-count)))
      (map-set game-statistics {round: current-round} 
               {total-entries: total-entries, prize-amount: total-pool, champions-count: winner-count})
      (var-set game-rounds-played current-round)
      (ok true))))

(define-public (choose-game-champions (random-seed uint))
  (let ((winner-count (var-get champions-to-select))
        (total-entries (var-get entries-count)))
    (begin
      (asserts! (verify-admin-privileges) ERR_UNAUTHORIZED_ACCESS)
      (asserts! (not (var-get game-status)) ERR_GAME_NOT_RUNNING)
      (asserts! (not (var-get champions-selection-complete)) ERR_CHAMPIONS_ALREADY_CHOSEN)
      (asserts! (> total-entries u0) ERR_CHAMPION_COUNT_ZERO)
      (var-set champions-selection-complete true)
      (let ((selection-result (fold process-champion-selection
                                    (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
                                    {seed: random-seed, champion-counter: u0, remaining-slots: winner-count})))
        (ok (get champion-counter selection-result))))))

(define-private (process-champion-selection (index uint) (context {seed: uint, champion-counter: uint, remaining-slots: uint}))
  (if (> (get remaining-slots context) u0)
    (let ((winning-entry-id (generate-random-winner (get seed context) index))
          (champion-address (get participant (unwrap-panic (map-get? entry-records {entry-id: (+ winning-entry-id u1)})))))
      (begin
        (map-set champion-registry {champion-id: (get champion-counter context)} {winner: champion-address, prize-claimed: false})
        {seed: (+ (get seed context) u1),
         champion-counter: (+ (get champion-counter context) u1),
         remaining-slots: (- (get remaining-slots context) u1)}))
    context))

(define-public (claim-champion-prize (champion-id uint))
  (let ((champion-info (unwrap! (map-get? champion-registry {champion-id: champion-id}) ERR_CHAMPION_ID_INVALID))
        (champion-address (get winner champion-info))
        (already-claimed (get prize-claimed champion-info)))
    (begin
      (asserts! (is-eq tx-sender champion-address) ERR_UNAUTHORIZED_ACCESS)
      (asserts! (not already-claimed) ERR_UNAUTHORIZED_ACCESS)
      (try! (send-prize-to-champion champion-address (var-get individual-champion-prize)))
      (asserts! (< champion-id (var-get champions-to-select)) ERR_CHAMPION_ID_INVALID)
      (map-set champion-registry {champion-id: champion-id} {winner: champion-address, prize-claimed: true})
      (ok true))))

(define-public (get-game-history (round-number uint))
  (let ((round-data (map-get? game-statistics {round: round-number})))
    (ok round-data)))

;; Read-Only Functions
(define-read-only (get-entry-fee)
  (ok (var-get entry-fee-amount)))

(define-read-only (get-prize-pool)
  (ok (var-get prize-pool-total)))

(define-read-only (get-user-entries (user-address principal))
  (ok (default-to u0 (map-get? participant-entries user-address))))

(define-read-only (get-total-entries)
  (ok (var-get entries-count)))

(define-read-only (is-game-active)
  (ok (var-get game-status)))

(define-read-only (get-game-deadline)
  (ok (var-get game-deadline-block)))

(define-read-only (get-refund-deadline)
  (ok (var-get refund-deadline-block)))

(define-read-only (get-commission-rate)
  (ok (var-get admin-commission-rate)))

(define-read-only (get-champion-details (champion-id uint))
  (ok (map-get? champion-registry {champion-id: champion-id})))

(define-read-only (are-champions-selected)
  (ok (var-get champions-selection-complete)))

(define-read-only (get-total-rounds-played)
  (ok (var-get game-rounds-played)))

(define-read-only (get-individual-prize-amount)
  (ok (var-get individual-champion-prize)))