#!/bin/bash
set -e

PASSWORD_DIR="/opt/perforce/servers/${P4NAME}/p4password"
PASSWORD_FILE="${PASSWORD_DIR}/super.password"
ROTATE_MARKER="${P4ROOT}/.rotate_super_password_on_first_boot"
LOCK_DIR="${PASSWORD_DIR}/.lock"

mkdir -p "${PASSWORD_DIR}"
chmod 700 "${PASSWORD_DIR}"

p4dctl start -t p4d $P4NAME
sudo service cron start
p4 trust -y -f

login_with_password() {
	local password="$1"
	[ -n "$password" ] || return 1

	if ! printf '%s\n' "$password" | p4 login > /dev/null 2>&1; then
		return 1
	fi

	printf '%s\n' "$password" | sudo -E -u perforce p4 login > /dev/null 2>&1 || true
	return 0
}

CURRENT_PASSWORD=""
if [ -f "${PASSWORD_FILE}" ]; then
	STORED_PASSWORD="$(head -n 1 "${PASSWORD_FILE}")"
	if login_with_password "${STORED_PASSWORD}"; then
		CURRENT_PASSWORD="${STORED_PASSWORD}"
	else
		echo "保存済みパスワードでのログインに失敗しました。P4PASSWDで再試行します。"
		if login_with_password "${P4PASSWD}"; then
			CURRENT_PASSWORD="${P4PASSWD}"
		fi
	fi
else
	if login_with_password "${P4PASSWD}"; then
		CURRENT_PASSWORD="${P4PASSWD}"
	fi
fi

if [ -z "${CURRENT_PASSWORD}" ] && [ -f "${ROTATE_MARKER}" ]; then
	echo "初回ローテーション対象ですが、現在のsuperパスワードでログインできません。" >&2
	exit 1
fi

if [ -z "${CURRENT_PASSWORD}" ] && [ ! -f "${ROTATE_MARKER}" ]; then
	echo "既存環境のため、superログインに失敗しても起動は継続します。" >&2
fi

if [ -f "${ROTATE_MARKER}" ]; then
	if mkdir "${LOCK_DIR}" 2>/dev/null; then
		trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' EXIT

		if [ -f "${ROTATE_MARKER}" ]; then
			NEW_PASSWORD="$(/usr/local/bin/generate-password.sh 16)"

			if p4 passwd <<EOF
${CURRENT_PASSWORD}
${NEW_PASSWORD}
${NEW_PASSWORD}
EOF
			then
				printf '%s\n' "${NEW_PASSWORD}" > "${PASSWORD_FILE}"
				chmod 600 "${PASSWORD_FILE}"
				chown perforce:perforce "${PASSWORD_FILE}" || true
				rm -f "${ROTATE_MARKER}"

				# 変更後パスワードで再ログイン
				login_with_password "${NEW_PASSWORD}"
			else
				echo "superユーザーのパスワード変更に失敗しました。" >&2
				exit 1
			fi
		fi
	fi
fi

cat /root/.p4trust > /opt/perforce/.p4trust
cat /root/.p4tickets > /opt/perforce/.p4tickets
exec /usr/bin/tail --pid=$(cat /var/run/p4d.$P4NAME.pid) -F "$P4ROOT/logs/log"