# teleproxy/repo

Package repository for [Teleproxy](https://github.com/teleproxy/teleproxy),
served at <https://teleproxy.github.io/repo/>.

## Install (RHEL 9, RHEL 10, AlmaLinux, Rocky, Fedora 41/42)

```sh
dnf install https://teleproxy.github.io/repo/teleproxy-release-latest.noarch.rpm
dnf install teleproxy
systemctl enable --now teleproxy
```

The setup RPM drops `/etc/yum.repos.d/teleproxy.repo` and the public
signing key. Subsequent updates flow through `dnf upgrade`.

## How it works

- Static `teleproxy` binaries built in `teleproxy/teleproxy`'s `release.yml`
  are wrapped with [nfpm](https://nfpm.goreleaser.com/) into RPMs. No
  per-distro rebuild — the binary has zero shared library deps.
- The main repo fires a `repository_dispatch` to this repo on every tag
  push; the workflow downloads the binaries from the release, signs the
  RPMs with the project key, runs `createrepo_c`, and deploys the tree to
  the `gh-pages` branch.
- Layout: `rpm/{el9,el10,fedora/41,fedora/42}/{x86_64,aarch64}/`. Room
  reserved for `apt/` later.
- Signing key is RSA 4096 with SHA-512 self-signature, satisfying the
  RHEL 9 rpm-sequoia requirement.

## Layout

```
RPM-GPG-KEY-teleproxy            public key
nfpm/teleproxy.yaml              main package config
nfpm/teleproxy-release.yaml      noarch setup RPM config
files/teleproxy.service          systemd unit
files/config.toml.example        sample config
files/teleproxy.repo             /etc/yum.repos.d/teleproxy.repo source
files/postinstall.sh             %post: useradd, randomize secret, preset
files/preremove.sh               %preun
files/postremove.sh              %postun
scripts/verify-key.sh            CI guard against SHA-1
scripts/build-rpms.sh            nfpm twice (amd64+arm64)
scripts/build-setup-rpm.sh       nfpm noarch setup RPM
scripts/publish-tree.sh          createrepo_c + sign + assemble _site/
.github/workflows/build-and-publish.yml
```

## Manual rebuild

The workflow runs automatically on tag dispatch from the main repo. To
rebuild manually for a specific version:

```sh
gh workflow run build-and-publish.yml -f tag=v4.2.1
```
