#!/usr/bin/env bash
set -euo pipefail

# Token jest krotkotrwaly i nie trafia do Terraform ani repozytorium.
: "${GITHUB_REPOSITORY_URL:?Ustaw GITHUB_REPOSITORY_URL}"
: "${RUNNER_TOKEN:?Ustaw krotkotrwaly RUNNER_TOKEN}"
: "${RUNNER_VERSION:?Ustaw wersje runnera z GitHub Releases}"
: "${RUNNER_SHA256:?Ustaw oficjalna sume SHA256 pakietu}"

RUNNER_DIR=/opt/actions-runner
ARCHIVE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${ARCHIVE}"

sudo apt-get update
sudo apt-get install -y ansible ca-certificates curl git jq python3-pip python3-venv

if ! command -v az >/dev/null 2>&1; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

sudo mkdir -p "${RUNNER_DIR}" /home/actions/.ssh
sudo chown -R actions:actions "${RUNNER_DIR}" /home/actions/.ssh

curl -fL "${DOWNLOAD_URL}" -o "/tmp/${ARCHIVE}"
echo "${RUNNER_SHA256}  /tmp/${ARCHIVE}" | sha256sum --check
sudo -u actions tar -xzf "/tmp/${ARCHIVE}" -C "${RUNNER_DIR}"
sudo "${RUNNER_DIR}/bin/installdependencies.sh"

if [[ ! -f /home/actions/.ssh/id_ed25519 ]]; then
  sudo -u actions ssh-keygen -t ed25519 -N "" -f /home/actions/.ssh/id_ed25519
fi

sudo -u actions "${RUNNER_DIR}/config.sh" \
  --unattended \
  --url "${GITHUB_REPOSITORY_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name ansible-mgmt \
  --labels vkickhamster-mgmt \
  --work _work

cd "${RUNNER_DIR}"
sudo ./svc.sh install actions
sudo ./svc.sh start
sudo deluser actions sudo || true

echo "Runner zostal uruchomiony. Klucz SSH do dodania na serwerach:"
sudo cat /home/actions/.ssh/id_ed25519.pub
