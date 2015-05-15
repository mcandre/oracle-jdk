#!/bin/bash

USER=`whoami`
if [ $USER != root ]; then
  echo "Must be root to run this script, please login as root and re-try"
  exit
fi

# see if libcwait.so is already being loaded
if [ -f "/etc/ld.so.preload" ] && [ -n "`grep libcwait /etc/ld.so.preload`" ]; then
  echo "Patch has already been applied"
  exit
else
  echo "Applying patch..."
fi

cat << EOF |
#include <errno.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/wait.h>
pid_t
__libc_wait (int *status)
{
  int res;
  asm volatile ("pushl %%ebx\n\t"
                "movl %2, %%ebx\n\t"
                "movl %1, %%eax\n\t"
                "int \$0x80\n\t"
                "popl %%ebx"
                : "=a" (res)
                : "i" (__NR_wait4), "0" (WAIT_ANY), "c" (status), "d" (0), "S" (0));
  return res;
}
EOF
gcc -m32 -O2 -shared -fpic -xc - -o /etc/libcwait.so

echo "Patch successfully applied"
