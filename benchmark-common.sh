TIME_FORMAT="%e, %E, %U, %S, %P, %I, %O, %W, %F, %R, %X, %p, %D, %K, %c, %w, %x, %C"
CSV_HEADINGS="# CPUs, Elapsed time (s), Elapsed time (hh:mm:ss), User-mode time (s), Kernel-mode time (s), CPU used (%), File system inputs, File system outputs, # Swaps, # Major page faults, # Minor page faults, Avg. shared text (KB), Avg. unshared stack size (KB), Avg. unshared data (KB), Avg. total memory usage (KB), # Involuntary context switches, # Voluntary context switches, Exit status, Executed command"
DATE=$(date "+%Y-%m-%d-%H-%M")
INITIAL_PWD="$(pwd)"
BASENAME=$(basename "$INITIAL_PWD")
TRIALS=3
TOTAL_PROCESSORS=$(lscpu --online --extended | grep --count yes)