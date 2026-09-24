# Mobile Laser Tag App — Implementation Sprint Plan

## Sprint 1: Core CI/CD & Infrastructure Setup

### Operation 1.1: Local Repository Setup & Multi-Project Branching Strategy

**Goal & Scope:** Establish a structured Git repository containing isolated directories for the Flutter client app, Go backend signaling server, and Docker configuration files, with automated branch protection rules.

**Technology Chosen:** Git & GitHub.
**Why:** Industry-standard version control. GitHub provides native integration with GitHub Actions for CI/CD pipelines without requiring self-hosted runners.

**Step-by-Step Construction Guide:**
1. Initialize a single Git monorepo with three top-level directories: `/mobile_app` (Flutter), `/backend` (Go), and `/infrastructure` (Docker/Coturn).
2. Create a `.gitignore` tailored for Flutter (ignoring build artifacts, `.dart_tool`, local environment configurations) and Go (ignoring compiled binaries, `vendor/`).
3. Configure GitHub repository protection rules on `main` to require pull request reviews and passing status checks before merging.

**Testing Strategy:** Test branching flow manually: create a feature branch `feature/repo-setup`, make a minor text change, push to remote, and verify that direct pushes to `main` are rejected.

**CI/CD & Safety Gate:** Create `.github/workflows/repository-validation.yml`. Configure it to trigger on PRs to `main` and execute a path-filtering check ensuring changed files belong to recognized directories.

---

### Operation 1.2: Go Backend Linter & Automated Testing Pipeline

**Goal & Scope:** Configure an automated CI pipeline that enforces Go code formatting, static analysis, and unit test execution on every commit.

**Technology Chosen:** GitHub Actions + golangci-lint + Go standard test runner (`go test`).
**Why:** Go's standard tooling is fast and native. golangci-lint aggregates multiple static analysis tools into a single fast binary.

**Step-by-Step Construction Guide:**
1. Create the backend Go module in `/backend` using `go mod init laser-tag-backend`.
2. Create a basic sanity test file `main_test.go` checking basic logic (e.g., verifying `1 + 1 == 2`).
3. Create `.github/workflows/go-ci.yml` targeting the `/backend` working directory.
4. Configure steps to set up Go, cache Go module dependencies (`go.sum`), run `golangci-lint-action`, and execute `go test -race -v -coverprofile=coverage.out ./...`.
5. Add a coverage gate step that parses `coverage.out` and fails the job if unit test coverage falls below 80%.

**Testing Strategy:** Introduce an intentional linting error (e.g., an unused variable) on a test branch and push. Verify that GitHub Actions catches the error and blocks the PR.

**CI/CD & Safety Gate:** Pull request merge access is gated behind passing `go-ci.yml` checks.

---

### Operation 1.3: Flutter Client Linter & Static Analysis Pipeline

**Goal & Scope:** Set up continuous integration for the Flutter application to catch static bugs, formatting errors, and broken Dart dependencies.

**Technology Chosen:** GitHub Actions + `flutter analyze` + `flutter test`.
**Why:** Catches type errors, null safety violations, and dead code early before native compilation starts.

**Step-by-Step Construction Guide:**
1. Create the Flutter project skeleton inside `/mobile_app` using the Flutter CLI.
2. Configure `analysis_options.yaml` to enforce strict null-safety and pedantic Dart linter rules.
3. Write a baseline widget test checking that the initial app loads without crashing.
4. Create `.github/workflows/flutter-ci.yml` targeting `/mobile_app`.
5. Set up job steps to install Flutter SDK, run `flutter pub get`, execute `flutter analyze`, and run `flutter test --coverage`.

**Testing Strategy:** Create a Dart file with a missing null check or undeclared variable. Push to GitHub and confirm the job fails at the `flutter analyze` step.

**CI/CD & Safety Gate:** The Flutter CI workflow acts as a mandatory status check on all incoming mobile pull requests.

---

## Sprint 2: Mobile Sensor DSP & Gesture Recognition Engine (Single-Phone POC)

### Operation 2.1: Raw IMU Sensor Acquisition Stream

**Goal & Scope:** Subscribe to high-frequency raw hardware accelerometer and gyroscope streams on the mobile device at 50–100 Hz.

**Technology Chosen:** Flutter `sensors_plus` package.
**Why:** Exposes platform-native Android (SensorManager) and iOS (CMMotionManager) telemetry via Dart EventChannel isolates with low overhead.

**Step-by-Step Construction Guide:**
1. Add `sensors_plus` to `/mobile_app/pubspec.yaml`.
2. Create a service class `SensorStreamManager` that exposes stream listeners for `userAccelerometerEvents` (A_x, A_y, A_z) and `gyroscopeEvents` (ω_x, ω_y, ω_z).
3. Set stream sampling intervals explicitly to 20 ms (50 Hz) to balance battery consumption with gesture responsiveness.

**Testing Strategy:** Run on a physical Android and iOS device. Output raw sensor values to a UI log text box. Verify that values stream continuously without dropping frames.

**CI/CD & Safety Gate:** Add unit tests using mock stream controllers to verify that `SensorStreamManager` correctly opens and closes subscriptions without leaking memory on disposal.

---

### Operation 2.2: Digital Signal Processing (DSP) — Exponential Moving Average (EMA) Low-Pass Filter

**Goal & Scope:** Filter out high-frequency micro-jitter and hand tremble from accelerometer data using an Exponential Moving Average (EMA) algorithm.

**Technology Chosen:** Pure Dart math function.
**Why:** Low-pass filtering adds zero external package dependencies, executing in O(1) time per sample with 10–30 ms latency.

**Step-by-Step Construction Guide:**
1. Define the low-pass filter mathematical formula:

   `S_t = α · X_t + (1 − α) · S_(t−1)`

   where X_t is the current raw sensor sample, S_(t−1) is the previous smoothed value, and α is the smoothing factor (tune between 0.1 and 0.3).
2. Implement an `EmaFilter` class that accepts a smoothing factor α and maintains internal state vectors for X, Y, Z axes.
3. Pass raw inputs from `SensorStreamManager` through `EmaFilter` before emitting them to downstream game systems.

**Testing Strategy:** Write unit tests passing a noisy sequence of mathematical data (e.g., a sine wave with added Gaussian noise) through `EmaFilter` and assert that the output variance is significantly lower than the input variance.

**CI/CD & Safety Gate:** Ensure unit tests for the filter algorithm execute in `flutter-ci.yml` with 100% line coverage.

---

### Operation 2.3: 9-Axis Quaternion Orientation Vector Derivation

**Goal & Scope:** Compute the phone's absolute 3D spatial orientation (Pitch, Roll, Yaw) in real time using full sensor fusion.

**Technology Chosen:** Flutter `flutter_posest` / native platform orientation channels or `vector_math` library.
**Why:** Standard accelerometers cannot measure heading around the vertical axis; combining accelerometer, gyroscope, and magnetometer data avoids gimbal lock and establishes true magnetic compass reference.

**Step-by-Step Construction Guide:**
1. Import `vector_math/vector_math_64.dart`.
2. Construct a quaternion representation Q = [w, x, y, z] updated continuously by sensor fusion data.
3. Extract the camera's pointing direction as a unit vector V_aim = [x_aim, y_aim, z_aim] by rotating the world reference forward vector [0, 1, 0]ᵀ using Q:

   `V_aim = Q · [0, 1, 0]ᵀ · Q*`

**Testing Strategy:** Write unit tests verifying that when Q represents identity (phone lying flat facing north), V_aim yields [0, 1, 0].

**CI/CD & Safety Gate:** Verify mathematical conversions pass static analysis and unit testing across multiple simulated rotation matrices in CI.

---

### Operation 2.4: Tactical Pistol Reload Gesture Deterministic State Machine (FSM)

**Goal & Scope:** Detect a two-stage pistol reload gesture: downward wrist flick + upward tilt (90°) within a maximum 1.5-second time window.

**Technology Chosen:** Deterministic Finite State Machine (FSM) in Dart.
**Why:** Eliminates machine learning model overhead, guarantees zero runtime battery impact, and provides predictable execution paths.

**Step-by-Step Construction Guide:**
1. Define states: `IDLE`, `MAG_EJECTED` (detected downward Z-acceleration spike > 15.0 m/s²), `SLIDE_PULLED` (detected pitch angle increase > 80°), and `RELOAD_COMPLETE`.
2. Implement a timeout guard timer (1.5 seconds). If the user reaches `MAG_EJECTED` but fails to perform `SLIDE_PULLED` before the timer expires, reset state to `IDLE`.
3. Trigger magazine replenishment event upon reaching `RELOAD_COMPLETE`.

**Testing Strategy:** Perform physical field tests with the device: attempt 50 valid pistol reload gestures and 50 erratic movements (running, jumping). Calculate false positive and false negative rates (target: > 95% accuracy).

**CI/CD & Safety Gate:** Write unit tests feeding mock time-series sensor logs into the FSM to verify state transitions and timeout resets without physical hardware attached.

---

### Operation 2.5: Pump-Action Shotgun & Assault Rifle Reload Gestures

**Goal & Scope:** Build FSM detectors for Pump-Action Shotgun (Z-axis forward-and-back rack) and Assault Rifle (double sharp horizontal X-axis shake).

**Technology Chosen:** Deterministic Finite State Machines in Dart.
**Why:** Ensures distinct physical motions are mapped cleanly to weapon classes described in the PRD specification.

**Step-by-Step Construction Guide:**
1. Implement `ShotgunReloadFsm`:
   - Transition `IDLE` → `PUMP_FORWARD` on Z-axis acceleration > +12.0 m/s².
   - Transition `PUMP_FORWARD` → `PUMP_BACK` on Z-axis acceleration < −12.0 m/s² within 600 ms.
2. Implement `RifleReloadFsm`:
   - Transition `IDLE` → `SHAKE_LEFT` on X-axis acceleration < −14.0 m/s².
   - Transition `SHAKE_LEFT` → `SHAKE_RIGHT` on X-axis acceleration > +14.0 m/s² within 500 ms.

**Testing Strategy:** Mock sensor events for both state machines in unit tests to verify state progression and strict time-window boundaries.

**CI/CD & Safety Gate:** Build unit tests verifying that shotgun motions do not accidentally trigger rifle reloads, enforcing state machine isolation.

---

## Sprint 3: Spatial Geometry & Local Coordinate Engine

### Operation 3.1: WGS84 GPS to Local ENU (East-North-Up) Projection Math

**Goal & Scope:** Convert raw global latitude/longitude/altitude coordinates into a local flat 3D Cartesian grid (X, Y, Z in meters) centered at the match host's position.

**Technology Chosen:** Custom Dart Spatial Math Package (`wgs84_to_enu`).
**Why:** Eliminates expensive spherical trigonometry (Haversine) during active hit checks. Local Euclidean distances run in O(1) time.

**Step-by-Step Construction Guide:**
1. Set Host position (Lat₀, Lon₀, Alt₀) as origin (0, 0, 0).
2. Convert target spherical coordinates (Lat, Lon, Alt) to Earth-Centered, Earth-Fixed (ECEF) Cartesian coordinates (X_ecef, Y_ecef, Z_ecef).
3. Transform ECEF coordinates to local East-North-Up (ENU) coordinates [x_enu, y_enu, z_enu]ᵀ using the rotation matrix derived from reference latitude and longitude:

```
[x_enu]   [ -sinLon₀            cosLon₀             0      ]   [ΔX_ecef]
[y_enu] = [ -sinLat₀cosLon₀    -sinLat₀sinLon₀    cosLat₀  ] · [ΔY_ecef]
[z_enu]   [  cosLat₀cosLon₀     cosLat₀sinLon₀    sinLat₀  ]   [ΔZ_ecef]
```

**Testing Strategy:** Write unit tests comparing output against known benchmark GPS reference points. Verify that two points known to be exactly 10.0 meters apart yield a calculated Euclidean distance of 10.0 ± 0.05 meters.

**CI/CD & Safety Gate:** Add spatial unit tests to `flutter-ci.yml` verifying float precision safety on 32-bit and 64-bit target architectures.

---

### Operation 3.2: Directional Target Vector Construction & Dot-Product Hit Calculation

**Goal & Scope:** Compute whether a shooter's aiming direction intersects a target player's position within a specific weapon's hit cone angle (θ) and range limit.

**Technology Chosen:** Vector Dot-Product in Dart.
**Why:** Executed in nanoseconds using pure vector arithmetic.

**Step-by-Step Construction Guide:**
1. Construct target vector V_target from Shooter position P_A to Target position P_B:

   `V_target = (P_B − P_A) / ‖P_B − P_A‖`

2. Calculate the cosine of the angle between the normalized aiming vector V_aim and V_target:

   `cos(θ) = V_aim · V_target`

3. Test hit condition:

   `θ = arccos(V_aim · V_target)`

   A hit is registered if θ ≤ (Weapon Cone Angle / 2) AND distance ‖P_B − P_A‖ ≤ Effective Weapon Range.

**Testing Strategy:** Test mathematical edge cases: target directly in front (θ = 0° → Hit), target at 90° → Miss, target directly behind (θ = 180° → Miss).

**CI/CD & Safety Gate:** Include matrix assertions for vector intersection math inside the CI suite.

---

### Operation 3.3: Dynamic Hit-Cone Scaling for GPS Drift Compensation

**Goal & Scope:** Dynamically widen the hit cone angle (θ) when targets are within 10 meters to compensate for hardware GPS position inaccuracy (3–5m uncertainty).

**Technology Chosen:** Piecewise Linear Function in Dart.
**Why:** Prevents player frustration from missed shots at close range caused by hardware inaccuracy.

**Step-by-Step Construction Guide:**
1. Define dynamic cone calculation function based on range d = ‖P_B − P_A‖:

```
θ_effective(d) = θ_base × (1 + (10 − d) / 10)   if d < 10 meters
θ_effective(d) = θ_base                          if d ≥ 10 meters
```

2. Pass calculated d into `calculateEffectiveConeAngle(double baseCone, double distance)` before running dot-product hit validation.

**Testing Strategy:** Unit test range inputs from 1 meter to 50 meters, confirming cone expansion smoothly doubles at 0 meters and stabilizes at base width beyond 10 meters.

**CI/CD & Safety Gate:** Add unit testing for non-negative distance boundaries and edge cases (d=0).

---

## Sprint 4: Backend Signaling, Lobby System & Synchronization

### Operation 4.1: Go WebSocket Connection Engine

**Goal & Scope:** Create a concurrent WebSocket backend capable of accepting client connections, maintaining active session state, and managing client heartbeats.

**Technology Chosen:** Go + Gorilla WebSocket package ([github.com/gorilla/websocket](https://github.com/gorilla/websocket)).
**Why:** Go channels and goroutines handle tens of thousands of concurrent persistent connections using minimal memory (< 100 MB RAM).

**Step-by-Step Construction Guide:**
1. Initialize `http.Server` in Go with upgraded HTTP-to-WebSocket endpoint `/ws`.
2. Implement `Client` struct holding client ID, room code, socket connection pointer, and outbound byte channel.
3. Implement `Hub` struct managing active client maps and register/unregister channels to safely handle concurrent joins/leaves without race conditions.
4. Write `readPump` and `writePump` loops with ping/pong keep-alive timers (ping every 30s) to detect dropped mobile cellular connections.

**Testing Strategy:** Write a load test script in Go spinning up 100 concurrent WebSocket client routines connecting simultaneously to the test server, verifying zero dropped messages or memory leaks.

**CI/CD & Safety Gate:** Include `go test -race ./...` in `go-ci.yml` to ensure no data races exist in WebSocket hub concurrency management.

---

### Operation 4.2: Lobby Management & 4-Digit Room Code Generator

**Goal & Scope:** Enable match hosts to create persistent game lobbies, generating unique 4-digit numeric room codes and equivalent QR code strings.

**Technology Chosen:** Go + Redis ([github.com/redis/go-redis/v9](https://github.com/redis/go-redis/v9)).
**Why:** In-memory storage provides sub-millisecond room lookups and key expiration support.

**Step-by-Step Construction Guide:**
1. Write a room code generator picking random 4-digit strings (0000–9999). Check Redis to ensure the code is not currently active.
2. Store room session state in Redis as a JSON hash with a 2-hour Time-To-Live (TTL):
   - `room_code: "4821"`
   - `host_id: "user_xyz"`
   - `settings: { match_duration: 600, weapon_mode: "ALL" }`
3. Provide WebSocket message handlers for `CREATE_LOBBY` and `JOIN_LOBBY`.

**Testing Strategy:** Unit test room code collisions by mocking a filled key space in Redis, verifying the generator retries until a free code is assigned.

**CI/CD & Safety Gate:** Run Redis integration tests in GitHub Actions using a service container (`services: redis: image: redis:alpine`).

---

### Operation 4.3: WebRTC SDP & ICE Candidate Signaling Relay

**Goal & Scope:** Facilitate WebRTC peer discovery by relaying SDP Offers, SDP Answers, and ICE Candidates between clients through the Go WebSocket server.

**Technology Chosen:** Go WebSocket JSON Signaling Protocol.
**Why:** Mobile devices cannot connect directly over P2P until they exchange public IP addresses and session capabilities through a central server.

**Step-by-Step Construction Guide:**
1. Define standard JSON message structures for `SIGNAL_OFFER`, `SIGNAL_ANSWER`, and `ICE_CANDIDATE`.
2. Implement target-routed message forwarding in Go: when Client A sends an offer targeted at Client B, the WebSocket server routes the payload directly to Client B's connection without parsing internal WebRTC contents.

**Testing Strategy:** Write an end-to-end integration test simulating two clients exchanging mock SDP payloads through the signaling hub, verifying sequence delivery order.

**CI/CD & Safety Gate:** Enforce payload validation in Go tests to reject malformed signaling packets missing target peer IDs.

---

### Operation 4.4: Coturn TURN Server Deployment Automation

**Goal & Scope:** Deploy a self-hosted Coturn TURN server inside Docker on a remote VPS to provide encrypted media/data relay fallback for strict symmetric NAT networks.

**Technology Chosen:** Coturn (`coturn/coturn` Docker image) on Hetzner/DigitalOcean VPS.
**Why:** Provides 99.9% connection success rate for 15% of cellular clients on strict NATs while avoiding expensive pay-per-gigabyte SaaS pricing.

**Step-by-Step Construction Guide:**
1. Create `/infrastructure/docker-compose.yml` containing the coturn container configuration.
2. Configure `turnserver.conf` with dynamic static-user credentials, listening port 3478, and relay port ranges (49152–65535).
3. Write a deployment GitHub Actions workflow (`deploy-turn.yml`) that uses SSH/SCP to pull updated configurations onto the production server automatically on merge to `main`.

**Testing Strategy:** Run `turnutils_uclient` CLI tool against the deployed TURN server address to verify successful authentication and packet relaying.

**CI/CD & Safety Gate:** Store credentials securely in GitHub Repository Secrets (`TURN_SECRET`, `VPS_SSH_KEY`). Never commit server credentials to version control.

---

## Sprint 5: Low-Latency P2P WebRTC Engine & Binary Serialization

### Operation 5.1: WebRTC Host-Authoritative Peer Connection Setup

**Goal & Scope:** Establish direct WebRTC P2P mesh links between non-host clients and the Host phone using Host-Authoritative Star Topology (O(N) links).

**Technology Chosen:** Flutter `flutter_webrtc` package.
**Why:** Offers native WebRTC bindings on iOS and Android. Star topology limits an 8-player match to 7 links on the host, reducing CPU and radio load by up to 85%.

**Step-by-Step Construction Guide:**
1. Add `flutter_webrtc` to `/mobile_app/pubspec.yaml`.
2. Instantiate `RTCPeerConnection` configured with Google public STUN servers (`stun:stun.l.google.com:19302`) and self-hosted Coturn TURN fallback credentials.
3. When a client joins a lobby, trigger Host to create an `RTCPeerConnection` for that specific client, attach data channels, and send an SDP offer via WebSocket signaling.

**Testing Strategy:** Test peer setup between two physical devices connected across separate networks (1 on Wi-Fi, 1 on 5G cellular) and verify connection state transitions to `RTCPeerConnectionStateConnected`.

**CI/CD & Safety Gate:** Write Flutter unit tests using mock peer connections to test state transition callbacks (`onIceCandidate`, `onConnectionState`).

---

### Operation 5.2: Dual WebRTC DataChannels Setup (Reliable vs. Unreliable)

**Goal & Scope:** Create two isolated communication channels per peer link: an unreliable/unordered UDP channel for raw continuous telemetry and a reliable/ordered channel for combat events.

**Technology Chosen:** `RTCDataChannel` (WebRTC).
**Why:** Sending position updates over unreliable channels prevents head-of-line blocking lag; reliable channels guarantee zero packet loss for shot and reload events.

**Step-by-Step Construction Guide:**
1. Create Unreliable DataChannel (Channel A):
   - Label: `"telemetry"`
   - Init parameters: `ordered = false`, `maxRetransmits = 0`.
2. Create Reliable DataChannel (Channel B):
   - Label: `"combat_events"`
   - Init parameters: `ordered = true`.

**Testing Strategy:** Instrument test scripts dropping 20% of packets artificially on Channel A and Channel B. Verify Channel A drops outdated frames cleanly while Channel B retransmits missing messages successfully.

**CI/CD & Safety Gate:** Verify data channel configurations via automated Flutter integration tests.

---

### Operation 5.3: Binary Bit-Packing Serialization Engine

**Goal & Scope:** Pack 3D spatial positions, orientation angle, health, and status flags into a compact 9-byte binary array payload for transmission at 15 Hz.

**Technology Chosen:** Pure Dart `ByteData` / Typed Data Buffers.
**Why:** Reduces payload size from ~65 bytes (JSON) to 9 bytes — an 86% reduction in cellular bandwidth.

**Step-by-Step Construction Guide:**
1. Define 9-byte binary structure:
   - Byte 0–1: Local X Position (16-bit signed int, 1 cm resolution)
   - Byte 2–3: Local Y Position (16-bit signed int, 1 cm resolution)
   - Byte 4–5: Yaw Heading Angle (16-bit unsigned int mapping 0°–360° to 0–65535)
   - Byte 6: Player Health & Status Flags (8-bit unsigned int)
   - Byte 7–8: Timestamp Offset (16-bit unsigned int in ms)
2. Write `BinaryEncoder` class using `ByteData(9)` to pack variables using bit-shifts.
3. Write corresponding `BinaryDecoder` class to unpack the 9-byte binary array back into Dart objects.

**Testing Strategy:** Write unit tests encoding random spatial telemetry objects, decoding the output byte buffer, and asserting that decoded values match original inputs within precise floating-point tolerance limits (X, Y ± 0.01m, Yaw ± 0.01°).

**CI/CD & Safety Gate:** Run bit-packing roundtrip serialization unit tests in `flutter-ci.yml`.

---

### Operation 5.4: Background Isolate Offloading for DSP & Serialization

**Goal & Scope:** Offload spatial transformations, vector dot products, and binary bit-packing to background Dart Isolates to preserve a steady 60 FPS UI thread.

**Technology Chosen:** Dart Isolates (`Isolate.spawn` / `compute`).
**Why:** Prevents CPU-bound vector math from causing frame stutter or input latency on the main UI rendering thread.

**Step-by-Step Construction Guide:**
1. Create long-lived isolate `SensorProcessingIsolate`.
2. Set up bi-directional `SendPort` and `ReceivePort` communication pipes between the UI isolate and background processing isolate.
3. Send raw sensor streams directly into `SensorProcessingIsolate`. Perform EMA filtering, orientation calculations, and binary packing inside the isolate, posting fully serialized 9-byte `Uint8List` buffers back to the UI thread for network transmission.

**Testing Strategy:** Run performance profiling tools in Flutter DevTools. Verify main thread frame times remain below 16.6 ms (60 FPS) during continuous background calculations.

**CI/CD & Safety Gate:** Add automated performance benchmarks in Flutter testing ensuring isolate spawn time and message passing latency remain < 2 ms.

---

### Operation 5.5: Target Dead Reckoning & Linear Interpolation (Lerp) Rendering

**Goal & Scope:** Render target player movement smoothly at 60 FPS while receiving position updates across the network at a lower rate of 15 Hz.

**Technology Chosen:** Linear Interpolation (Lerp) on the Flutter Animation Frame Loop.
**Why:** Saves network bandwidth and mobile device battery life while maintaining fluid visual movement on screen.

**Step-by-Step Construction Guide:**
1. Store last two received network positions P_old and P_new along with arrival timestamps T_old and T_new.
2. On each UI frame tick (t), compute interpolation factor:

   `α = (t − T_old) / (T_new − T_old)`

3. Compute smooth rendered position:

   `P_render = P_old + α · (P_new − P_old)`

**Testing Strategy:** Write unit tests evaluating P_render at α = 0.0, 0.5, 1.0, asserting exact expected midpoint coordinates.

**CI/CD & Safety Gate:** Validate math functions in CI tests to guarantee α is clamped strictly between 0.0 and 1.0 to prevent wild spatial overshooting.

---

## Sprint 6: Combat Engine & Authoritative State Resolution

### Operation 6.1: Reliable Firing Event Broadcast Protocol

**Goal & Scope:** Transmit a high-priority, reliable `SHOT_FIRED` combat event containing shooter coordinates, aiming vector, weapon ID, and precise timestamp across WebRTC.

**Technology Chosen:** WebRTC Reliable DataChannel B + Precise Millisecond Clock Synchronization.
**Why:** Guarantees shot packets are delivered without loss and in correct chronological order.

**Step-by-Step Construction Guide:**
1. Capture current synchronized match timestamp T_shot, origin location P_shooter, aiming vector V_aim, and active weapon specification upon screen tap / trigger pull.
2. Construct JSON/Binary shot payload and emit over Reliable DataChannel B to the Host node.
3. Trigger local haptic feedback motor and audio weapon sound effect immediately for responsive client feedback.

**Testing Strategy:** Simulate network packet delays up to 200 ms and verify that `SHOT_FIRED` events arrive without loss on the receiving device.

**CI/CD & Safety Gate:** Run unit tests asserting payload validation for missing or out-of-range timestamp attributes.

---

### Operation 6.2: Target-Authoritative Health State Machine & Timestamped Conflict Resolution

**Goal & Scope:** Manage individual player health transitions (ALIVE, DOWN, DEAD) locally on the target's device and resolve simultaneous shot race conditions using absolute timestamps.

**Technology Chosen:** Target-Authoritative State Machine in Dart.
**Why:** Each device maintains authoritative control over its own health state, preventing host-side cheating while resolving simultaneous kill race conditions deterministically.

**Step-by-Step Construction Guide:**
1. Implement Target Health FSM (HP starting at 100).
2. Upon receiving a `SHOT_FIRED` event, the Target device performs spatial vector hit validation locally (Operation 3.2).
3. If hit is validated and Target state is `ALIVE`:
   - Reduce HP by weapon damage.
   - If HP ≤ 0, transition state to `DEAD` at timestamp T_death = T_shot and broadcast `PLAYER_DIED(killer_id, timestamp)` event to all peers.
4. If a second shot arrives with timestamp T2 > T_death, reject the fatal shot and emit a `LATE_HIT` notification to the secondary shooter.

**Testing Strategy:** Write unit tests simulating two incoming fatal shot packets spaced 12 ms apart (T1 = 1000ms, T2 = 1012ms). Assert that Player 1 receives the kill attribution while Player 2 receives a `LATE_HIT` acknowledgment.

**CI/CD & Safety Gate:** Include timestamp conflict test cases in `flutter-ci.yml`.

---

### Operation 6.3: Post-Match Analytics & MVP Award Calculation Engine

**Goal & Scope:** Calculate match MVP badges (Sharpshooter, Gunslinger, Relentless, Speed Reload) and populate the "Who Got Who" hit matrix upon match timer expiration.

**Technology Chosen:** Pure Dart Analytics Engine.
**Why:** Processes combat logs deterministically on match conclusion without external API network latency.

**Step-by-Step Construction Guide:**
1. Aggregate match combat logs into a data structure containing shots fired, hits landed, kills, deaths, and average reload times per player.
2. Implement badge assignment functions:
   - **Sharpshooter:** max(Hits / Shots Fired)
   - **Gunslinger:** max(Total Kills)
   - **Relentless:** max(Kills / Deaths)
   - **Speed Reload:** min(Average Reload Duration)
3. Construct a 2D matrix grid array `WhoGotWho[PlayerA][PlayerB]` representing mutual tag counts.

**Testing Strategy:** Feed mock match combat logs into `PostMatchEngine` in unit tests and assert correct award distribution across test edge cases (e.g., ties, 0 shots fired).

**CI/CD & Safety Gate:** Validate statistical calculations using automated unit tests inside the CI pipeline.

---

## Sprint 7: Database Architecture & Monetization Engine

### Operation 7.1: PostgreSQL Database Schema & Migration Framework

**Goal & Scope:** Design and execute persistent PostgreSQL schema migrations for user accounts, historic match records, and active subscription tokens.

**Technology Chosen:** PostgreSQL + `golang-migrate/migrate`.
**Why:** Provides transactional ACID-compliant data safety for financial subscriptions and user stats. golang-migrate tracks versioned SQL scripts safely in Git.

**Step-by-Step Construction Guide:**
1. Create directory `/backend/migrations`.
2. Write SQL migration script `000001_init_schema.up.sql`:
   - `users` table: `id` (UUID), `display_name`, `email`, `created_at`.
   - `matches` table: `id` (UUID), `host_id`, `duration_seconds`, `ended_at`.
   - `user_tokens` table: `user_id`, `tokens_remaining` (INT), `last_reset_timestamp` (TIMESTAMPTZ).
   - `subscriptions` table: `user_id`, `tier` (ENUM: `'FREE'`, `'DAY_PASS'`, `'PRO'`, `'BATTLE_HOST'`), `expires_at` (TIMESTAMPTZ).
3. Integrate automatic schema migration execution on application backend boot in Go.

**Testing Strategy:** Run migration up and down scripts against a local test PostgreSQL Docker container, verifying schemas build and tear down cleanly without errors.

**CI/CD & Safety Gate:** Run dynamic database migration steps in `go-ci.yml` using a live PostgreSQL service container.

---

### Operation 7.2: Daily Match Token Cap & Host Override Business Logic

**Goal & Scope:** Enforce the rolling 24-hour 2-match daily limit for free tier users while enabling host-override logic for paying Battle Host subscribers.

**Technology Chosen:** Go Middleware / Business Logic Layer in PostgreSQL transactions.
**Why:** Implements the core monetization model defined in Section 5 of the specification document.

**Step-by-Step Construction Guide:**
1. Implement match entry validation function `CanUserJoinMatch(userID, roomCode)` in Go:
   - Check if room host has an active `BATTLE_HOST` subscription. If true, grant entry immediately (Host Override).
   - If host is free tier, check target user subscription tier. If `PRO` or `DAY_PASS`, grant entry.
   - If target user is `FREE`, check `user_tokens`:
     - If `last_reset_timestamp` is older than 24 hours, reset `tokens_remaining = 2` and update the reset timestamp.
     - If `tokens_remaining > 0`, decrement `tokens_remaining` by 1 and grant entry.
     - Otherwise, reject match join request with HTTP status `402 Payment Required`.

**Testing Strategy:** Write unit tests covering all 5 user monetization scenarios: Free user under limit, Free user over limit, Free user in Battle Host lobby, Pro user, and Day Pass user.

**CI/CD & Safety Gate:** Verify payment entitlement verification paths using unit test suites running in GitHub Actions.

---

## Step-by-Step Execution Summary Plan

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          INCREMENTAL BUILDING SEQUENCE                          │
└─────────────────────────────────────────────────────────────────────────────────┘

  [Sprint 1] Repository & CI/CD Pipelines (Go + Flutter + GitHub Actions)
      │
      v
  [Sprint 2] Single-Phone Sensor DSP & Gesture FSMs (Flutter Isolates)
      │
      v
  [Sprint 3] Spatial Geometry & Coordinate Math (WGS84 -> ENU Projection)
      │
      v
  [Sprint 4] Backend Signaling Server & WebSockets (Go + Redis + Coturn)
      │
      v
  [Sprint 5] Low-Latency P2P WebRTC Data Engine (Dual Channels + Bit-Packing)
      │
      v
  [Sprint 6] Combat Engine & Conflict Resolution (Target-Authoritative State)
      │
      v
  [Sprint 7] Persistence, Monetization & Daily Token Limits (Postgres + Auth)
```

Each operation in this sequence is self-contained. The workflow follows a strict cycle: write unit tests for the specific logic, construct the single operation, test it locally, push to a feature branch, verify that CI/CD checks pass, and merge into `main` before moving on to the next operation.
