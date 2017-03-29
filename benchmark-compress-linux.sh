#!/bin/bash

source benchmark-common.sh

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

echo "Beginning compression of Linux kernel, with $TRIALS trials for each number of CPUs"
echo "$CSV_HEADINGS" > "$COMPRESS_KERNEL_CSV"
for i in $(seq $TOTAL_PROCESSORS); do
  ARCHIVE_NAME="linux.tar.bz2.$i"
  echo "  Compressing to $ARCHIVE_NAME with $i CPUs"

  for j in $(seq $TRIALS); do
    echo "    Trial $j"
    echo -n "$i, " >> "$COMPRESS_KERNEL_CSV"

    /usr/bin/time \
      --quiet \
      --output="$COMPRESS_KERNEL_CSV" \
      --append \
      --format "$TIME_FORMAT" \
      bash -c "pbzip2 --compress -9 -b9 --stdout --quiet --keep -p$i \"$TAR_NAME\" > \"$ARCHIVE_NAME\""
    rm -f "$ARCHIVE_NAME"
  done
done

echo "Done!  See results in $COMPRESS_KERNEL_CSV"