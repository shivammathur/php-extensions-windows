#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

assets=(./ext/*/*.dll)
if ((${#assets[@]} == 0)); then
  echo 'No extension DLLs found to publish' >&2
  exit 1
fi

: "${CF_R2_AWS_S3_ENDPOINT:?Cloudflare R2 endpoint is required}"
: "${AWS_ACCESS_KEY_ID:?Cloudflare R2 access key is required}"
: "${AWS_SECRET_ACCESS_KEY:?Cloudflare R2 secret key is required}"
if ! command -v aws >/dev/null 2>&1; then
  pip3 install --upgrade awscli >/dev/null
fi

for asset in "${assets[@]}"; do
  aws --endpoint-url "$CF_R2_AWS_S3_ENDPOINT" s3 cp "$asset" \
    "s3://php-extensions-windows/$(basename "$asset")" \
    --cache-control 'public, max-age=300' --only-show-errors
done

if gh release view builds >/dev/null 2>&1; then
  gh release upload builds "${assets[@]}" --clobber
else
  gh release create builds "${assets[@]}" -t builds -n builds
fi
