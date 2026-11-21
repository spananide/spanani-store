#!/usr/bin/env bash
set -euo pipefail

# Build LiveContainer with spanani Store embedded as SideStoreApp.framework.

# Default is the nightly: 3.8.0 still ships the old split store (AltStoreCore.framework) and its hooks do not fit our single-binary store.
LC_TAG="${LC_TAG:-nightly}"
LC_REF="$LC_TAG"
[ "$LC_TAG" = nightly ] && LC_REF=main

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <path-to-SpananiStore.ipa> <output-ipa-path>" >&2
    exit 1
fi

INPUT_IPA="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
mkdir -p "$(dirname "$2")"
OUTPUT_IPA="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Step 1: Download and extract official LiveContainer+SideStore release
echo "==> Downloading and extracting LiveContainer $LC_TAG"
gh release download "$LC_TAG" -R LiveContainer/LiveContainer -p 'LiveContainer+SideStore.ipa' -O "$WORK/lc.ipa"
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

# Step 4: Download dylibify tool and widget entitlements
echo "==> Downloading dylibify and widget entitlements"
curl -fsSL -o "$WORK/dylibify" https://github.com/LiveContainer/dylibify/releases/download/1.0/dylibify && chmod +x "$WORK/dylibify"
curl -fsSL -o "$WORK/widget.xml" "https://raw.githubusercontent.com/LiveContainer/LiveContainer/$LC_REF/.github/sidelc/LiveWidgetExtension_adhoc.xml"

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
