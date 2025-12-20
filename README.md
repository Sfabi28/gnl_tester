# Get Next Line Tester

A robust, strict, and comprehensive testing suite for the 42 **get_next_line** project. It covers Mandatory and Bonus parts, tests various `BUFFER_SIZE` configurations, handles `stdin`, and includes deep memory leak detection via Valgrind.

## 📁 1. Installation

Ensure that the folder of this tester (`gnl_tester`) is located **INSIDE** the root of your `get_next_line` project.

**Correct Directory Structure:**
```text
/get_next_line_root
    ├── get_next_line.c
    ├── get_next_line.h
    ├── get_next_line_utils.c
    ├── (bonus files if applicable)
    └── gnl_tester/          <--- YOU ARE HERE
          ├── launch.sh
          ├── main.c
          ├── utils/
          ├── files/         (test input files)
          └── test_results.log
```

Ensure that the path is right and set a proper timeout time considering valgrind **INSIDE** the `launch.sh` file

```text
   SOURCE_PATH="../"
   TIME=10
```

## 🚀 2. First Run


Before running the tester for the first time, you must grant execution permissions to the main script:

```bash
chmod +x launch.sh
```

## ⚙️ 3. Usage Commands
-----------------
The tester supports different modes.

```text
Command,Description
./launch.sh, Runs ALL tests (Mandatory + Bonus) with random Buffer Sizes.
./launch.sh m, Runs MANDATORY tests only.
./launch.sh b, Runs BONUS tests only (Multiple FDs).
```

## 📊 4. Results Legend
-----------------

```text
Output Comparison

    [OK] : The line returned matches the expected output exactly.

    [KO] : The output differs (wrong line, missing newline, extra characters, or NULL when not expected).

Memory Analysis (if Valgrind is active)

    [MOK] : Memory OK. No leaks and no invalid reads.

    [MKO] : Memory KO. Leaks detected (check your free() calls and static variable management).
```

## 📝 5. What is tested
-----------
```text
The suite runs your get_next_line against the system's getline or expected outputs under stress conditions:

    Buffer Size Chaos: Tests run with BUFFER_SIZE = 1, 42, 9999, 10000000 (and random values).

    Edge Cases:

        Empty files.

        Files with very long lines (no newline).

        Files ending without a newline.

        Standard Input (stdin) reading.

    Bonus Logic:

        Reading from multiple File Descriptors simultaneously without losing state.

        Alternating between FDs (e.g., Read FD 3, then FD 4, then FD 3 again).
```
Happy debugging!🖥️