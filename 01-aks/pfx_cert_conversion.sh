#!/bin/bash

# This script expects input from STDIN as a JSON-encoded String with the property 'pfx_base64'
# It returns the public and private key as a JSON-encoded String with the properties 'public_key_base64' and 'private_key_base64'
# No files are written, everything is piped.
#
# Tested on MacOS X and Linux (Ubuntu 18.04).

function error_exit() {
  echo "$1" 1>&2
  exit 1
}

function check_deps() {
  test -f $(which openssl) || error_exit "openssl command not detected in path, please install it"
  test -f $(which jq) || error_exit "jq command not detected in path, please install it"
}

function parse_input() {
  # jq reads from stdin so we don't have to set up any inputs, but let's validate the outputs
  eval "$(jq -r '@sh "export PFX_BASE64=\(.pfx_base64)"')"
  if [[ -z "${PFX_BASE64}" ]]; then exit 1; fi
}

function read_public_key() {
  script_dir=$(dirname $0)
  echo -n ${PFX_BASE64} | base64 -d  | openssl pkcs12 -clcerts -nokeys -passin pass:"" | base64
}

function read_private_key() {
  script_dir=$(dirname $0)
  echo -n ${PFX_BASE64} | base64 -d  | openssl pkcs12 -nocerts -nodes -passin pass:"" | base64
}

function produce_output() {
  public_key_contents=$(read_public_key)
  private_key_contents=$(read_private_key)

  #echo "DEBUG: public_key_contents ${public_key_contents}" 1>&2
  #echo "DEBUG: private_key_contents ${private_key_contents}" 1>&2
  jq -n \
    --arg public_key "$public_key_contents" \
    --arg private_key "$private_key_contents" \
    '{"public_key_base64":$public_key,"private_key_base64":$private_key}'
}

# main()
check_deps
parse_input
#echo "DEBUG: received: $PFX_BASE64" 1>&2
produce_output
