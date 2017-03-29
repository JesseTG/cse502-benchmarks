#!/bin/bash

source benchmark-common.sh

COMPILE_KERNEL_CSV="$INITIAL_PWD/compile-kernel-$DATE.csv"

if [[ ! -d "$LINUX_KERNEL" ]]; then
  echo "Cloning linux kernel"
  git clone --quiet --depth=1 "https://github.com/torvalds/linux.git"
  LINUX_KERNEL="$(readlink --canonicalize ./linux)"
else
  LINUX_KERNEL=$(readlink --canonicalize "$LINUX_KERNEL")
  echo "Using linux kernel at $LINUX_KERNEL"
fi
cd "$LINUX_KERNEL"

echo "Beginning to compile the Linux kernel with $TRIALS trials for each number of CPUs"
echo "$CSV_HEADINGS" > "$COMPILE_KERNEL_CSV"
for i in $(seq $TOTAL_PROCESSORS); do
  echo "  Compressing to $ARCHIVE_NAME with $i CPUs"

  for j in $(seq $TRIALS); do
    echo "    Trial $j"
    echo -n "$i, " >> "$COMPILE_KERNEL_CSV"

    make tinyconfig
    /usr/bin/time \
      --output="$COMPILE_KERNEL_CSV" \
      --append \
      --format "$TIME_FORMAT" \
      bash -c "make -j$i"

    git clean -xdf
  done
done

echo "Done!  See results in $COMPILE_KERNEL_CSV"