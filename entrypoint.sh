#!/usr/bin/env bash
# Writes the O'FAIRe portal configuration from environment variables, then runs
# the given command (Tomcat by default, or `fairness-cache`).
#
#   SERVER_DEFAULT_PORTAL  portal name (default: ontoportal); also read by O'FAIRe
#                          itself as the portal for requests that do not name one
#   PORTAL_URL             REST API of the OntoPortal instance
#   PORTAL_APIKEY          apikey used to read the API (or PORTAL_APIKEY_FILE)
#   PORTAL_ADMIN_APIKEY    optional admin apikey, so private ontologies are assessed
#                          too (or PORTAL_ADMIN_APIKEY_FILE); defaults to PORTAL_APIKEY
#   CACHE_ENABLED          true: answer from the cache file built by fairness-cache
#   CACHE_FILE_PATH        location of that cache file
set -euo pipefail

read_secret() {  # $1 = variable name; NAME_FILE wins over NAME
  local file_var="${1}_FILE"
  if [ -n "${!file_var:-}" ]; then
    tr -d '\n' < "${!file_var}"
  else
    printf '%s' "${!1:-}"
  fi
}

portal="$(printf '%s' "${SERVER_DEFAULT_PORTAL:-ontoportal}" | tr '[:upper:]' '[:lower:]')"
export SERVER_DEFAULT_PORTAL="${portal}"
url="${PORTAL_URL:?PORTAL_URL is required}"
apikey="$(read_secret PORTAL_APIKEY)"
admin_apikey="$(read_secret PORTAL_ADMIN_APIKEY)"
admin_apikey="${admin_apikey:-${apikey}}"
cache_enabled="${CACHE_ENABLED:-true}"
cache_file="${CACHE_FILE_PATH:-/data/fairness/save.json}"

# O'FAIRe looks the portal up by the lower-cased `name` property, so the directory
# name and `name` must be the same string.
conf_dir="/usr/local/tomcat/webapps/ROOT/WEB-INF/classes/config/portals/${portal}"
mkdir -p "${conf_dir}"
umask 077
cat > "${conf_dir}/config.properties" <<EOF
name=${portal}
url=${url}
apikey=${apikey}
adminApikey=${admin_apikey}
cacheFilePath=${cache_file}
cacheEnabled=${cache_enabled}
EOF
umask 022

# The cache writer creates only the last path component.
mkdir -p "$(dirname "${cache_file}")"

echo "[ofaire] portal=${portal} api=${url} cache=${cache_enabled}:${cache_file}" >&2
exec "$@"
