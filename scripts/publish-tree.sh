#!/bin/sh
# Assemble the gh-pages tree from freshly-built RPMs.
#
# Inputs (env):
#   GNUPGHOME         - gpg home with the signing private key imported
#   SIGNING_KEY_UID   - uid/keyid to pass to gpg --local-user
#
# Inputs (filesystem):
#   out/teleproxy-*.x86_64.rpm
#   out/teleproxy-*.aarch64.rpm
#   out/teleproxy-release-*.noarch.rpm
#   RPM-GPG-KEY-teleproxy
#
# Output:
#   _site/rpm/{el9,el10,fedora/41,fedora/42}/{x86_64,aarch64}/
#   _site/RPM-GPG-KEY-teleproxy
#   _site/teleproxy-release-1-1.noarch.rpm
#   _site/index.html
set -eu

: "${SIGNING_KEY_UID:=Teleproxy}"

if ! command -v createrepo_c >/dev/null 2>&1; then
    echo "publish-tree.sh: createrepo_c not installed" >&2
    exit 2
fi

AMD64_RPM=$(ls out/teleproxy-*.x86_64.rpm 2>/dev/null | head -1)
ARM64_RPM=$(ls out/teleproxy-*.aarch64.rpm 2>/dev/null | head -1)
RELEASE_RPM=$(ls out/teleproxy-release-*.noarch.rpm 2>/dev/null | head -1)

[ -n "$AMD64_RPM" ] || { echo "missing x86_64 rpm in out/" >&2; exit 1; }
[ -n "$ARM64_RPM" ] || { echo "missing aarch64 rpm in out/" >&2; exit 1; }
[ -n "$RELEASE_RPM" ] || { echo "missing teleproxy-release noarch rpm in out/" >&2; exit 1; }

rm -rf _site
mkdir -p _site

# Six leaf dirs, same RPMs in each (binary is static; one build serves all)
for DISTRO in rpm/el9 rpm/el10 rpm/fedora/41 rpm/fedora/42; do
    for ARCH in x86_64 aarch64; do
        LEAF="_site/$DISTRO/$ARCH"
        mkdir -p "$LEAF"
        if [ "$ARCH" = "x86_64" ]; then
            cp "$AMD64_RPM" "$LEAF/"
        else
            cp "$ARM64_RPM" "$LEAF/"
        fi
        # Setup RPM is noarch but include it in every leaf so dnf upgrade works
        cp "$RELEASE_RPM" "$LEAF/"
        createrepo_c --update "$LEAF"
        gpg --batch --yes --local-user "$SIGNING_KEY_UID" \
            --detach-sign --armor \
            --output "$LEAF/repodata/repomd.xml.asc" \
            "$LEAF/repodata/repomd.xml"
    done
done

# Top-level files
cp RPM-GPG-KEY-teleproxy _site/RPM-GPG-KEY-teleproxy
cp "$RELEASE_RPM" "_site/$(basename "$RELEASE_RPM")"
# Stable URL alias for the latest setup RPM
cp "$RELEASE_RPM" _site/teleproxy-release-latest.noarch.rpm

# Minimal index so the root URL isn't a 404
cat > _site/index.html <<'HTML'
<!doctype html>
<meta charset="utf-8">
<title>Teleproxy package repository</title>
<style>body{font-family:system-ui,sans-serif;max-width:40em;margin:3em auto;padding:0 1em;color:#222}code{background:#f4f4f4;padding:.1em .3em;border-radius:.2em}pre{background:#f4f4f4;padding:1em;border-radius:.3em;overflow-x:auto}</style>
<h1>Teleproxy package repository</h1>
<p>One-step install on RHEL 9/10, AlmaLinux, Rocky, and Fedora 41/42:</p>
<pre>dnf install https://teleproxy.github.io/repo/teleproxy-release-latest.noarch.rpm
dnf install teleproxy
systemctl enable --now teleproxy</pre>
<p>Public signing key: <a href="RPM-GPG-KEY-teleproxy">RPM-GPG-KEY-teleproxy</a></p>
<p>Source and CI: <a href="https://github.com/teleproxy/repo">github.com/teleproxy/repo</a></p>
HTML

echo "publish-tree.sh: built _site/ tree:"
find _site -maxdepth 4 -type d
