#!/bin/bash

source benchmark-common.sh

UPX_CSV="upx-$DATE.csv"

mkdir -p "llvm-bins-backup"
echo "Downloading LLVM"
wget "http://releases.llvm.org/4.0.0/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz"
echo "Extracting LLVM"
tar -xf "clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz"
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
    cp -r "llvm-bins-backup" "llvm-bins"

    /usr/bin/time \
      --output="$UPX_CSV" \
      --append \
      --format "$TIME_FORMAT" \
      bash -c "ls bins | xargs --max-lines=1 --max-procs=$i upx --best --ultra-brute -qqq"

    rm -rf "./llvm-bins"
  done
done

rm -rf "./llvm-bins" "llvm-bins-backup" "clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz"

echo "Done!  See results in $UPX_CSV"