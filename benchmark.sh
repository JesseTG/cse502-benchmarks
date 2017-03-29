#!/bin/bash

# /usr/bin/time --output=compress.log --append --format "$TIME_FORMAT" bash -c "$COMMAND"

################################################################################
# General constants #
################################################################################
TIME_FORMAT="%e, %E, %U, %S, %P, %I, %O, %W, %F, %R, %X, %p, %D, %K, %c, %w, %x, %C"
CSV_HEADINGS="Elapsed time (s), Elapsed time (hh:mm:ss), User-mode time (s), Kernel-mode time (s), CPU used (%), File system inputs, File system outputs, # Swaps, # Major page faults, # Minor page faults, Avg. shared text (KB), Avg. unshared stack size (KB), Avg. unshared data (KB), Avg. total memory usage (KB), # Involuntary context switches, # Voluntary context switches, Exit status, Executed command"
DATE=$(date "+%Y-%m-%d-%H-%M")
INITIAL_PWD="$(pwd)"
BASENAME=$(basename "$INITIAL_PWD")
KERNEL_TRIALS=10


TOTAL_PROCESSORS=$(grep -c ^processor /proc/cpuinfo)
HALF_PROCESSORS=$(( $TOTAL_PROCESSORS / 2 ))
################################################################################

################################################################################
# Compress the Linux Kernel
################################################################################
COMPRESS_KERNEL_CSV="compress-kernel-$DATE.csv"

if [[ ! -d "$LINUX_KERNEL" ]]; then
  echo "Cloning linux kernel"
  git clone --quiet --depth=1 "https://github.com/torvalds/linux.git"
  LINUX_KERNEL="$(readlink -f ./linux)"
else
  LINUX_KERNEL=$(readlink -f "$LINUX_KERNEL")
  echo "Using linux kernel at $LINUX_KERNEL"
fi
cd "$LINUX_KERNEL"
LINUX_KERNEL_REVISION=$(git rev-parse HEAD)
TAR_NAME="linux-$LINUX_KERNEL_REVISION.tar"
git archive --format=tar HEAD --prefix="linux/" --output="../$BASENAME/$TAR_NAME"
echo "Archived linux kernel to $TAR_NAME"
cd "$INITIAL_PWD"

echo "Beginning compression of Linux kernel, with $KERNEL_TRIALS trials for each number of CPUs"
echo "$CSV_HEADINGS" > "$COMPRESS_KERNEL_CSV"
for i in $(seq $TOTAL_PROCESSORS); do
  ARCHIVE_NAME="linux.tar.bz2.$i"
  echo "  Compressing to $ARCHIVE_NAME with $i CPUs"

  for j in $(seq $KERNEL_TRIALS); do
    echo "    Trial $j"
    /usr/bin/time \
      --output="$COMPRESS_KERNEL_CSV" \
      --append \
      --format "$TIME_FORMAT" \
      bash -c "pbzip2 --compress -9 -b9 --stdout --quiet --keep -p$i \"$TAR_NAME\" > \"$ARCHIVE_NAME\""
    rm -f "$ARCHIVE_NAME"
  done
done
################################################################################

# Qt meta info: http://download.qt.io/official_releases/qt/5.8/5.8.0/qt-opensource-linux-x64-5.8.0.run.mirrorlist
for i in $(seq 6); do

  # Sequential Compress
  for bin in $(ls bins); do
    upx --best --ultra-brute -qqq "$bin"
  done

  # Sequential Decompress
  for bin in $(ls bins); do
    upx -d -q "$bin"
  done
done

#
for i in $(seq 6); do
  # Two-core compress
  ls bins | xargs --max-lines=1 --max-procs=2 upx --best --ultra-brute -qqq
  ls bins | xargs --max-lines=1 --max-procs=$HALF_PROCESSORS upx --best --ultra-brute -qqq
  ls bins | xargs --max-lines=1 --max-procs=$TOTAL_PROCESSORS upx --best --ultra-brute -qqq
done
# Two cores

# Half cores

# All cores