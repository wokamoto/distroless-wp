#!/usr/bin/sh
set -eu

WP_PATH="${WP_PATH:-/var/www/html/wp}"
MARKER_FILE="${WP_LANGUAGE_MARKER_FILE:-/var/www/html/.wp-language-updated}"
MAX_RETRIES="${WP_LANGUAGE_UPDATE_RETRIES:-30}"
SLEEP_SECONDS="${WP_LANGUAGE_UPDATE_SLEEP_SECONDS:-2}"

if [ "${WP_LANGUAGE_UPDATE_FORCE:-0}" != "1" ] && [ -f "${MARKER_FILE}" ]; then
  exit 0
fi

if [ ! -f "${WP_PATH}/wp-config.php" ]; then
  echo "wp-config.php not found at ${WP_PATH}; skipping language update."
  exit 0
fi

IS_INSTALLED_ERR_FILE="/tmp/wp-core-is-installed.err"

attempt=1
while [ "${attempt}" -le "${MAX_RETRIES}" ]; do
  if wp --allow-root --path="${WP_PATH}" core is-installed >/dev/null 2>"${IS_INSTALLED_ERR_FILE}"; then
    rm -f "${IS_INSTALLED_ERR_FILE}"
    break
  fi

  if grep -qi "not installed" "${IS_INSTALLED_ERR_FILE}"; then
    echo "WordPress is not installed; skipping language update."
    rm -f "${IS_INSTALLED_ERR_FILE}"
    exit 0
  fi

  if [ "${attempt}" -eq "${MAX_RETRIES}" ]; then
    echo "Unable to determine WordPress installation state after ${MAX_RETRIES} attempts."
    cat "${IS_INSTALLED_ERR_FILE}" || true
    rm -f "${IS_INSTALLED_ERR_FILE}"
    exit 1
  fi

  echo "Waiting for WordPress installation check (${attempt}/${MAX_RETRIES})"
  attempt=$((attempt + 1))
  sleep "${SLEEP_SECONDS}"
done

attempt=1
while [ "${attempt}" -le "${MAX_RETRIES}" ]; do
  if wp --allow-root --path="${WP_PATH}" language core update \
    && wp --allow-root --path="${WP_PATH}" language plugin update --all \
    && wp --allow-root --path="${WP_PATH}" language theme update --all; then
    touch "${MARKER_FILE}"
    exit 0
  fi

  if [ "${attempt}" -eq "${MAX_RETRIES}" ]; then
    echo "WP language update failed after ${MAX_RETRIES} attempts."
    exit 1
  fi

  echo "Retrying WP language update (${attempt}/${MAX_RETRIES})"
  attempt=$((attempt + 1))
  sleep "${SLEEP_SECONDS}"
done
