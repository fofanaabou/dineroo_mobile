"""Print the highest versionCode currently visible on Play Store tracks.

Writes `latest_version_code=<int>` to stdout, meant to be appended to
$GITHUB_OUTPUT by the caller.

Note: the Android Publisher API has no endpoint to list every versionCode
ever uploaded, only those in each track's *current* releases. A versionCode
that was fully replaced and dropped from every track's release list won't
show up here. That's an accepted limitation: Google Play permanently
registers every versionCode it has seen and rejects re-uploading one, even
if it's no longer visible on any track — so this scenario surfaces as a
loud failure on the "Upload to Play Store" step, not a silent bad release.
"""

import json
import os
import sys

from google.oauth2 import service_account
from googleapiclient.discovery import build

PACKAGE_NAME = "com.dineroo.app"


def main() -> None:
    creds = service_account.Credentials.from_service_account_info(
        json.loads(os.environ["PLAY_API_JSON"]),
        scopes=["https://www.googleapis.com/auth/androidpublisher"],
    )
    service = build("androidpublisher", "v3", credentials=creds)

    edit_id = (
        service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()["id"]
    )
    try:
        tracks = (
            service.edits()
            .tracks()
            .list(editId=edit_id, packageName=PACKAGE_NAME)
            .execute()
        )
    finally:
        service.edits().delete(editId=edit_id, packageName=PACKAGE_NAME).execute()

    max_version_code = 0
    for track in tracks.get("tracks", []):
        for release in track.get("releases", []):
            for code in release.get("versionCodes", []):
                max_version_code = max(max_version_code, int(code))

    if max_version_code == 0:
        sys.exit("Could not find any existing versionCode on Play Store — refusing to guess.")

    print(f"latest_version_code={max_version_code}")


if __name__ == "__main__":
    main()
