# FPGA Switch Counter Game

A two-player digital game implemented on an Intel Cyclone V FPGA using the
DE10-Standard development board, VHDL, an SCOMP soft processor, and custom
assembly code.

The project extends the SCOMP system with a custom memory-mapped peripheral
that monitors the board's ten switches and independently counts rising,
falling, or both types of signal transitions.

Assembly software running on SCOMP controls the game sequence, countdown
timer, scoring, LEDs, seven-segment displays, and peripheral configuration.

## Project Overview

Two players compete by toggling switches SW0 and SW9 during a timed round.

The system:

- Waits for the players to start the game
- Runs a pre-game countdown
- Configures which switch transitions should be counted
- Counts switch transitions in hardware
- Tracks each player's score
- Displays the remaining time and scores
- Mirrors switch states to the board LEDs
- Ends the round when the timer expires

## Hardware Platform

- Terasic DE10-Standard
- Intel Cyclone V FPGA
- 10 slide switches
- 10 red LEDs
- Seven-segment displays
- 50 MHz board clock

## System Architecture

The project uses an SCOMP-based processor system with a custom
memory-mapped switch-counting peripheral.

                   ┌──────────────────┐
                   │      SCOMP       │
                   │  16-bit Processor│
                   └────────┬─────────┘
                            │
                     Memory-Mapped I/O
                            │
          ┌─────────────────┼────────────────┐
          │                 │                │
          ▼                 ▼                ▼
   Switch Counter        Timer           Displays
     Peripheral         Peripheral       LEDs / HEX
          │
          ▼
      SW[9:0]

The SCOMP assembly program coordinates the game while the custom VHDL
peripheral performs switch-edge detection and counting in hardware.

## Custom Switch Counter Peripheral

A major part of the project was implementing a custom VHDL peripheral capable
of monitoring all ten FPGA board switches.

The peripheral contains ten independent 16-bit counters.

Each counter records transitions from its corresponding switch.

The peripheral can be configured to detect:

- Falling edges
- Rising edges
- Both rising and falling edges

Previous and current switch states are stored internally and compared to
detect transitions.

## Memory-Mapped I/O

The peripheral is accessed by the SCOMP processor through memory-mapped I/O.

| Address | Function |
|---------|----------|
| 0x60–0x69 | Individual switch counters |
| 0x6A | Current switch states |
| 0x6B | Edge-detection configuration |
| 0x6C | Counter reset mask |

This allows assembly software to configure and read the hardware peripheral
using normal IN and OUT instructions.

## Edge Detection

The peripheral stores both the previous and current state of each switch.

For every clock cycle, the states are compared.

A transition from:

0 → 1

is detected as a rising edge.

A transition from:

1 → 0

is detected as a falling edge.

Depending on the selected configuration, the corresponding 16-bit counter is
incremented.

## Game Software

The game logic was written in SCOMP assembly.

The program is organized into reusable subroutines including:

- ResetMemoryLEDs
- UpdateLEDs
- WaitStart
- StartRound
- CountDown
- StartGame
- PlayGame
- EndGame
- GetScore

The assembly program manages the game state while communicating with the
hardware peripherals through memory-mapped I/O.

## Game Flow

Start
  ↓
Reset Scores / LEDs
  ↓
Wait for Players
  ↓
5-Second Countdown
  ↓
Configure Edge Detection
  ↓
Start Timed Round
  ↓
Read Hardware Counters
  ↓
Update Scores / Displays
  ↓
Timer Expires
  ↓
Final Score

## FPGA / VHDL Concepts

This project provided experience with:

- VHDL
- FPGA development
- Digital logic design
- Finite-state systems
- Memory-mapped I/O
- Hardware/software interfaces
- Edge detection
- Hardware counters
- Bidirectional data buses
- Peripheral address decoding
- Quartus Prime
- Intel Cyclone V FPGA development

## Assembly Programming

The software uses SCOMP assembly instructions for:

- Memory access
- Arithmetic
- Bitwise operations
- Conditional branching
- Subroutine calls
- Timer polling
- Peripheral reads and writes

This project demonstrated how software running on a processor can communicate
with custom digital hardware implemented directly on an FPGA.

## Challenges

One of the major challenges was integrating the custom switch-counter
peripheral with the existing SCOMP architecture.

The peripheral needed to:

- Respond only to its assigned I/O address range
- Correctly drive the shared I/O data bus during read operations
- Accept configuration data during write operations
- Independently maintain ten counters
- Correctly detect different types of switch transitions
- Allow software-controlled counter resets

The assembly program then had to coordinate the peripheral, timer, LEDs, and
seven-segment displays to create a complete working game.

## What I Learned

This project gave me hands-on experience with the boundary between hardware
and software.

Rather than implementing the entire application purely in software, part of
the functionality was implemented as custom digital hardware while assembly
software controlled the overall system.

I gained experience with:

- Designing custom FPGA peripherals
- VHDL signal and process logic
- Memory-mapped register interfaces
- Assembly programming
- Hardware/software co-design
- FPGA debugging
- Quartus project integration
- Digital I/O

## Future Improvements

Possible improvements include:

- Hardware switch debouncing
- Input synchronization
- Additional game modes
- Improved score displays
- Configurable game duration
- Additional player inputs
- More robust reset behavior
- Refactoring the peripheral into smaller reusable VHDL modules

## Author

Ian Hall  
Electrical Engineering  
Georgia Institute of Technology
