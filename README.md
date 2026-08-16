# 🛗 Smart Elevator Controller with SCAN Scheduling (Verilog)

## 📌 Project Overview

This project implements an **industry-style Smart Elevator Controller** using **Verilog HDL**, combining a **Finite State Machine (FSM)** with a **SCAN-based request scheduler** to model real-world elevator systems.

Unlike basic elevator designs, this system maintains multiple pending floor requests and intelligently services them according to the current elevator direction.

The design emphasizes **efficient request scheduling, safety, deterministic operation, and modular RTL architecture**, making it a strong demonstration of **RTL design, digital system architecture, and verification skills**.

---

## 🚀 Key Highlights (Why this is Top-Level)

* 🔄 **SCAN-based elevator request scheduling**
* 🧠 **FSM-based control logic with 9 states**
* 📋 **16-bit pending request tracking for 16 floors**
* ⬆️⬇️ **Direction-aware request servicing**
* 🔁 **Automatic direction reversal**
* ⚠️ **Safety-first design**

  * Emergency stop
  * Overweight protection
  * Power failure handling
  * Generator backup
* 🧪 **23 comprehensive test cases**
* 🖥️ **Waveform + simulation log validation**
* 🧩 **Modular RTL architecture**

---

## 🧠 System Architecture

```text
User Requests → Pending Request Register → SCAN Scheduler → Target Floor Logic → Elevator FSM → Outputs
```

### 📦 Modules

| Module            | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `elevator_top`    | Handles pending requests, SCAN scheduling and integrates the elevator FSM |
| `elevator`        | FSM controlling movement, safety, doors and cabin controls                |
| `elevator_top_tb` | Testbench with 23 scenarios                                               |

---

## 🔄 SCAN-Based Scheduling (Core Innovation)

### Problem Solved:

Traditional elevator FSM:

❌ May not efficiently handle multiple pending requests
❌ Can cause unnecessary direction changes
❌ Does not intelligently service requests based on direction

### Solution:

✔ Pending requests are stored using a **16-bit request register**
✔ Requests above and below the current floor are checked
✔ Elevator continues in the current direction while requests exist
✔ Elevator reverses direction when there are no more requests in the current direction

### Example:

```text
Current Floor = 8
Requests = 2, 4, 6, 9, 12, 15
Direction = UP

8 → 9 → 12 → 15

No more requests above

15 → 6 → 4 → 2
```

This demonstrates the **SCAN elevator scheduling behavior**.

---

## 📋 Pending Request Control Logic

The controller uses:

```verilog
reg [15:0] pending_requests;
```

Each bit represents one floor:

```text
pending_requests[0]  → Floor 0
pending_requests[1]  → Floor 1
...
pending_requests[15] → Floor 15
```

### Request Handling:

```text
1 → Request pending
0 → No request
```

When a request is received:

```text
request_valid = 1
        ↓
pending_requests[floor] = 1
```

When the elevator reaches the target floor:

```text
current_floor == target_floor
        ↓
Clear corresponding request
```

---

## 🧭 Direction Control

The scheduler uses:

```text
direction
r_above
r_below
```

### When Moving UP:

```text
Request above?
      ↓
     YES → Continue UP
      ↓
     NO
      ↓
Request below?
      ↓
     YES → Reverse DOWN
```

### When Moving DOWN:

```text
Request below?
      ↓
     YES → Continue DOWN
      ↓
     NO
      ↓
Request above?
      ↓
     YES → Reverse UP
```

This allows the elevator to follow the SCAN scheduling behavior.

---

## 🎯 Target Floor Handling

The scheduler generates:

```text
next_target
```

which is used to update:

```text
target_floor
```

### UP Direction

* Searches pending requests above the current floor
* Selects the next request
* If no request exists above, searches below

### DOWN Direction

* Searches pending requests below the current floor
* Selects the next request
* If no request exists below, searches above

This ensures that pending requests are serviced according to the current scan direction.

---

## 🧠 FSM Design

### States Implemented:

| State               | Function               |
| ------------------- | ---------------------- |
| `electricity_check` | Power failure handling |
| `idle`              | Waiting state          |
| `move_up`           | Upward motion          |
| `move_down`         | Downward motion        |
| `door_open`         | Door opening           |
| `weight_check`      | Load verification      |
| `alarm`             | Overweight condition   |
| `door_close`        | Door closing           |
| `emergency_stop`    | Emergency halt         |

---

## ⚡ Power Handling

| Condition                      | Behavior               |
| ------------------------------ | ---------------------- |
| Electricity = 1                | Normal operation       |
| Electricity = 0, Generator = 0 | Power failure handling |
| Electricity = 0, Generator = 1 | Generator backup       |

✔ Provides power-aware elevator control.

---

## ⚖️ Overweight Protection

```text
weight = 500
```

* Movement is prevented during overweight condition
* Alarm is activated
* Elevator resumes normal operation after weight becomes safe

---

## 🚨 Emergency Stop

```text
e_stop = 1
```

* Elevator enters the `emergency_stop` state
* Elevator movement is stopped
* Emergency condition is handled safely
* Emergency-stop behavior is tested during movement and idle conditions

---

## 🚪 Door Control Logic

* Opens when the elevator reaches the target floor
* Controlled by the elevator FSM
* Door open and close outputs are generated separately
* Door operation is verified through simulation

---

## 💡 Light and Fan Control

The elevator supports cabin controls:

```text
light
fan
```

with corresponding outputs:

```text
light_on
fan_on
```

These signals model basic elevator cabin utilities.

---

## 📊 Simulation Waveform

The waveform verifies:

* FSM transitions
* SCAN scheduling behavior
* Direction changes
* Pending request handling
* Floor movement
* Target floor selection
* Door operations
* Safety conditions

![Waveform](images/waveform.png)

**Waveform file path:**

```text
images/waveform.png
```

---

## 🖥️ Simulation Log Output

The simulation log provides **cycle-accurate debugging visibility**.

### Includes:

* Current state
* Current floor
* Target floor
* Next target
* Direction
* Requests above
* Requests below
* Request status
* Motor control signals
* Door control signals
* Light and fan status
* Alarm status
* Emergency stop
* Weight

### Sample:

```text
T=8565000 | rst=0 elec=1 gen=0 | floor=7 CUR_FLOOR=8 TARGET=8 next_target=8 direction=1 r_above=0 r_below=0 req=1 current_state=idle | UP=0 DOWN=0 | DO=0 DC=1 | L=1 F=1 ALARM=0 | estop=0 weight=400
```

📄 Full logs: `simulation_log.txt`

---

## 🧪 Testbench Coverage (23 Cases)

### ✔ Functional Tests

* Movement up/down
* Same-floor request
* Sequential requests
* Multiple floor requests

### ✔ SCAN Scheduling Tests

* Multiple pending requests
* Requests above and below current floor
* Direction continuation
* Automatic direction reversal
* Multiple inside requests
* Multiple outside requests

### ✔ Safety Tests

* Overweight condition
* Emergency stop during movement
* Emergency stop at idle
* Power failure
* Generator backup

### ✔ Edge Cases

* UP and DOWN active together
* Requests at different times
* Multiple calls at the same time
* Repeated floor requests
* Mixed inside/outside calls

---

## 🔧 Design Methodology

✔ Synchronous design using `posedge clk`

✔ Modular RTL architecture

✔ Separation of:

* Request management
* Direction control
* SCAN scheduling
* Target floor generation
* Elevator FSM
* Output control

✔ Combinational logic for request analysis and target selection

✔ Sequential logic for request storage, direction and target updates

---

## 🎯 Scheduling Priority

```text
Emergency Stop
       ↓
Power Handling
       ↓
Overweight Protection
       ↓
SCAN Scheduling
       ↓
Normal Elevator Operation
```

---

## 📂 Project Structure

```text
smart-elevator-controller/
│
├── elevator.v
├── elevator_top.v
├── elevator_top_tb.v
├── simulation_log.txt
├── README.md
│
└── images/
    └── waveform.png
```

### 📊 Waveform Location

```text
images/waveform.png
```

### 🖥️ Simulation Log Location

```text
simulation_log.txt
```

---

## 🚀 How to Run (Vivado)

1. Open project in **Xilinx Vivado**
2. Add RTL files:

   ```text
   elevator.v
   elevator_top.v
   ```
3. Add testbench:

   ```text
   elevator_top_tb.v
   ```
4. Run: **Run Behavioral Simulation**
5. Observe:
   → Waveforms
   → Console output

---

## 🛠️ Tools Used

* Verilog HDL
* Xilinx Vivado

---

## 📈 Skills Demonstrated

* RTL Design
* FSM Design
* SCAN Scheduling Algorithm
* Elevator Control Logic
* Digital System Architecture
* Sequential & Combinational Logic
* Testbench Development
* Verification & Debugging
* Safety Logic
* Edge Case Handling

---

## 👨‍💻 Author

**SHAIK ABDUL MATHEEN**

---

## 📌 Acknowledgement

This project demonstrates *advanced RTL design concepts* including:

* FSM Design
* SCAN-Based Scheduling
* Multi-Floor Request Handling
* Real-World Elevator Control
* Safety and Power Management
* Hardware Verification using Testbench

It is a strong example of *industry-level digital design thinking*.
