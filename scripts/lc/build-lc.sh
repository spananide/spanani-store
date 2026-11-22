#!/usr/bin/env bash
set -euo pipefail

# Build LiveContainer with spanani Store embedded as SideStoreApp.framework.

# Inputs come from our own pinned release (LiveContainer nightly 2026-11-20; 3.8.0 still ships the old
# split store whose hooks do not fit our single-binary store). To move to a newer LC, upload new files
# to the lc-base release and update the checksums below.
LC_BASE="https://github.com/spananide/spanani-store/releases/download/lc-base"

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <path-to-SpananiStore.ipa> <output-ipa-path>" >&2
    exit 1
fi

INPUT_IPA="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
mkdir -p "$(dirname "$2")"
OUTPUT_IPA="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Step 1: Download pinned LiveContainer base, dylibify tool and widget entitlements
echo "==> Downloading pinned LiveContainer base"
curl -fsSL -o "$WORK/lc.ipa" "$LC_BASE/LiveContainer%2BSideStore.ipa"
curl -fsSL -o "$WORK/dylibify" "$LC_BASE/dylibify" && chmod +x "$WORK/dylibify"
curl -fsSL -o "$WORK/widget.xml" "$LC_BASE/LiveWidgetExtension_adhoc.xml"
(cd "$WORK" && shasum -a 256 -c - <<'EOF'
d520ae1003f21afa1c38004dfd760b1b305b4df4b63ff54fb6859e836a6f5088  lc.ipa
6d23f6a2fc4d8442f87caa1161aebe6ecaafd0e8c41ce205da007efb04fc82c7  dylibify
1f6bcd298a18abf692bd5bf167179ce5e78d3a4bd635ce12f04f586a0e143335  widget.xml
EOF
)
mkdir "$WORK/lc" && unzip -q "$WORK/lc.ipa" -d "$WORK/lc"
LC_APP="$WORK/lc/Payload/LiveContainer.app"
FW="$LC_APP/Frameworks/SideStoreApp.framework"

# Step 2: Extract our store IPA
echo "==> Extracting spanani Store IPA"
mkdir "$WORK/store" && unzip -q "$INPUT_IPA" -d "$WORK/store"
if [ ! -d "$WORK/store/Payload/SideStore.app" ]; then
    echo "ERROR: SideStore.app not found in $INPUT_IPA" >&2
    exit 1
fi

# Step 3: Keep LiveContainer's guest-info file
echo "==> Preserving LiveContainer guest-info file"
if [ ! -f "$FW/LCAppInfo.plist" ]; then
    echo "ERROR: LCAppInfo.plist not found in $FW" >&2
    exit 1
fi
cp "$FW/LCAppInfo.plist" "$WORK/LCAppInfo.plist"

# Step 5: Replace store framework and convert executable to dylib
echo "==> Replacing Store framework and dylibifying"
rm -rf "$FW"
mv "$WORK/store/Payload/SideStore.app" "$FW"
"$WORK/dylibify" "$FW/SideStore" "$FW/SideStore.dylib"
rm "$FW/SideStore"
mv "$FW/SideStore.dylib" "$FW/SideStore"
ldid -S"" "$FW/SideStore"
cp "$WORK/LCAppInfo.plist" "$FW/"
# The sideloader (isideload) only gives the store an app group + certificate when the framework
# carries SideStore's bundle id, and LC's hooks override our own id at runtime anyway.
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.SideStore.SideStore" "$FW/Info.plist"

# Step 6: Overwrite intents and patch appintents metadata
echo "==> Updating intents and metadata"
cp "$FW/Intents.intentdefinition" "$FW/ViewApp.intentdefinition" "$LC_APP/"
rm -rf "$LC_APP/Metadata.appintents"
cp -R "$FW/Metadata.appintents" "$LC_APP/Metadata.appintents"
sed -i '' 's/9SideStore20RefreshAllAppsIntentV/16SideStoreSupport20RefreshAllAppsIntentV/g' "$LC_APP/Metadata.appintents/extract.actionsdata"
sed -i '' 's/9SideStore26RefreshAllAppsWidgetIntentV/16SideStoreSupport26RefreshAllAppsWidgetIntentV/g' "$LC_APP/Metadata.appintents/extract.actionsdata"

# Step 7: Update and resign widget extension
echo "==> Updating widget extension"
rm -rf "$LC_APP/PlugIns/LiveWidgetExtension.appex"
mv "$FW/PlugIns/AltWidgetExtension.appex" "$LC_APP/PlugIns/LiveWidgetExtension.appex"
W="$LC_APP/PlugIns/LiveWidgetExtension.appex"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.kdt.livecontainer.LiveWidget" "$W/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable LiveWidgetExtension" "$W/Info.plist"
mv "$W/AltWidgetExtension" "$W/LiveWidgetExtension"
ldid -S"$WORK/widget.xml" "$W/LiveWidgetExtension"

# Step 8: Package output IPA
echo "==> Packaging LiveContainer+spanani.ipa"
rm -f "$OUTPUT_IPA"
cd "$WORK/lc" && zip -qr "$OUTPUT_IPA" Payload -x "._*" -x ".DS_Store" -x "__MACOSX"

# Step 9: Verification
echo "==> Verifying build output"
STORE_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$FW/Info.plist")"
if [ "$STORE_BUNDLE_ID" != "com.SideStore.SideStore" ]; then
    echo "ERROR: Expected CFBundleIdentifier com.SideStore.SideStore, got $STORE_BUNDLE_ID" >&2
    exit 1
fi
echo "Store CFBundleIdentifier: $STORE_BUNDLE_ID"
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$W/Info.plist"
ls -la "$FW/SideStore"
file "$FW/SideStore"
unzip -l "$OUTPUT_IPA" | grep -E 'SideStoreApp.framework/(SideStore|Info.plist|LCAppInfo.plist)$|LiveWidgetExtension.appex/LiveWidgetExtension$'
