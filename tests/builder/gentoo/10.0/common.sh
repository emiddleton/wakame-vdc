
export LANG=C
export LC_ALL=C

which gem >/dev/null && {
  export PATH="$(gem environment gemdir)/bin:$PATH"
} || :
