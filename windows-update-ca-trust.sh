#!/bin/bash

function windows-update-ca-trust()
{
 shopt -s nullglob

 tdir="$(mktemp.exe -d)"
 pushd "$tdir"
 echo src=$src store=$store
 [ "$src" == "null" ] && certutil -split -store $store > /dev/null || certutil -$src -split -store $store > /dev/null

 for i in Blob*.crt; do
  read fp subj <<<$(openssl.exe x509 -noout -fingerprint -subject -inform DER -in "$i" |\
    sed '/^SHA1 Fingerprint=/{s/^SHA1 Fingerprint=//;s/://g}; /^subject= /{s/^subject= //};' 
   )
  echo " $subj"
  if [ -f /etc/pki/ca-trust/source/anchors/$src-$store-$fp.crt ]; then
   > $src-$store-$fp.crt
  else
   openssl x509 -inform DER -text -in "$i" > $src-$store-$fp.crt
  fi
  rm "$i"
 done

 for i in /etc/pki/ca-trust/source/anchors/$src-$store-*; do 
  tfn="$(basename "$i")"
  [ -f "$tfn" ] || rm -v "$i"
 done

 for i in $src-$store-*.crt; do
  if [ -s "$i" ]; then
   mv -fv $i /etc/pki/ca-trust/source/anchors/
  else
   rm "$i"
  fi
 done

 popd

 rmdir "$tdir"

 update-ca-trust
}

#store=ca
#store=authroot
#store=root
#src=null
#src=user
#src=service
#src=enterprise
#src=grouppolicy

src=grouppolicy; store=root

windows-update-ca-trust

src=enterprise; store=root

windows-update-ca-trust

src=null; store=authroot

windows-update-ca-trust



