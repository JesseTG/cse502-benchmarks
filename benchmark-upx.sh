#!/bin/bash

source benchmark-common.sh

UPX_CSV="upx-$DATE.csv"

echo "Downloading LLVM"
wget "http://releases.llvm.org/4.0.0/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz"
echo "Extracting LLVM"
tar -xf "clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz"

echo "Finding all executable files in LLVM..."
mkdir -p "llvm-bins-backup"
find "./clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10" -type f -print \
  | file --separator "" --files-from - \
  | grep "x86-64" \
  | cut --fields=1 --delimiter=" " \
  | xargs -l -I '{}' cp {} "llvm-bins-backup"

echo "Beginning compression of LLVM, with $TRIALS trials for each number of CPUs"
echo "$CSV_HEADINGS" > "$UPX_CSV"
for i in $(seq $TOTAL_PROCESSORS); do
  echo "  Compressing with $i CPUs"

  for j in $(seq $TRIALS); do
    echo "    Trial $j"
    echo -n "$i, " >> "$UPX_CSV"
    echo "      Copying binaries..."
    cp -r "llvm-bins-backup" "llvm-bins"

    echo "      Compressing binaries..."  # This is the part that's timed
    /usr/bin/time \
      --quiet \
      --output="$UPX_CSV" \
      --append \
      --format "$TIME_FORMAT" \
      bash -c "ls llvm-bins | xargs --max-lines=1 --max-procs=$i -I '{}' upx -qqq ./llvm-bins/{}"

    echo "      Removing compressed binaries..."
    rm -rf "./llvm-bins";
  done;
done;

rm -rf "./llvm-bins" "llvm-bins-backup" "clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz"

echo "Done!  See results in $UPX_CSV"