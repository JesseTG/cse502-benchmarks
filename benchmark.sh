#!/bin/bash

# /usr/bin/time --output=compress.log --append --format "$TIME_FORMAT" bash -c "$COMMAND"

################################################################################
# General constants #
################################################################################
TIME_FORMAT="%e, %E, %U, %S, %P, %I, %O, %W, %F, %R, %X, %p, %D, %K, %c, %w, %x, %C"
CSV_HEADINGS="Elapsed time (s), Elapsed time (hh:mm:ss), User-mode time (s), Kernel-mode time (s), CPU used (%), File system inputs, File system outputs, # Swaps, # Major page faults, # Minor page faults, Avg. shared text (KB), Avg. unshared stack size (KB), Avg. unshared data (KB), Avg. total memory usage (KB), # Involuntary context switches, # Voluntary context switches, Exit status, Executed command"
DATE=$(date "+%Y-%m-%d-%H-%M")

TOTAL_PROCESSORS=$(grep -c ^processor /proc/cpuinfo)
HALF_PROCESSORS=$(( $TOTAL_PROCESSORS / 2 ))
################################################################################

################################################################################
# Compress the Linux Kernel
################################################################################
PBZIP2_FLAGS="--compress -9 -b9 --stdout --quiet --keep"
PIGZ_FLAGS="--best --quiet --keep --stdout"
PIXZ_FLAGS="-9 -k"
declare -a COMPRESS_KERNEL_METHODS=(
  "bzip2 --compress --best --stdout --quiet --keep"
  "pbzip2 $PBZIP2_FLAGS -p2"
  "pbzip2 $PBZIP2_FLAGS -p$HALF_PROCESSORS"
  "pbzip2 $PBZIP2_FLAGS -p$TOTAL_PROCESSORS"
  "gzip --best --quiet --keep --stdout"
  "pigz $PIGZ_FLAGS --processes 2"
  "pigz $PIGZ_FLAGS --processes $HALF_PROCESSORS"
  "pigz $PIGZ_FLAGS --processes $TOTAL_PROCESSORS"
  "xz --compress -9 --keep --quiet --stdout"
  "pixz $PIXZ_FLAGS -p 2"
  "pixz $PIXZ_FLAGS -p $HALF_PROCESSORS"
  "pixz $PIXZ_FLAGS -p $TOTAL_PROCESSORS"
)

git clone --quiet --depth=1 "https://github.com/torvalds/linux.git"
cd linux
LINUX_KERNEL_REVISION=$(git rev-parse HEAD)
cd ..


tar --no-auto-compress --create --file=linux-$LINUX_KERNEL_REVISION.tar --exclude=.git --format=gnu --blocking-factor=20 --quoting-style=escape ./linux

echo "$CSV_HEADINGS" > compress-kernel-$DATE.csv
for compress in "${COMPRESS_KERNEL_METHODS[@]}"; do

  for i in $(seq 1); do
    $compress linux.tar
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