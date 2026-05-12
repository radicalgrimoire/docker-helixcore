#!/bin/bash
set -e

: "${P4CONFIG:?P4CONFIG is not set}"
P4ROOT_PARENT="$(dirname "$P4ROOT")"
PASSWORD_DIR="${P4ROOT_PARENT}/p4password"
PASSWORD_FILE="${PASSWORD_DIR}/super.password"
ROTATE_MARKER="${P4ROOT}/.rotate_super_password_on_first_boot"
LOCK_FILE="${PASSWORD_DIR}/.rotate_super_password.lock"

mkdir -p "${PASSWORD_DIR}"
chmod 700 "${PASSWORD_DIR}"

run_p4_as_perforce() {
	sudo -H -E -u perforce "$@"
}

write_p4config() {
	local password="$1"
	[ -n "$password" ] || return 1

	cat > "${P4CONFIG}" <<EOF
P4USER=${P4USER}
P4PORT=${P4PORT}
P4PASSWD=${password}
EOF
	chown perforce:perforce "${P4CONFIG}" || true
	chmod 600 "${P4CONFIG}" || true
}

p4dctl start -t p4d "${P4NAME}"
sudo service cron start
run_p4_as_perforce p4 trust -y -f

login_with_password() {
	local password="$1"
	[ -n "$password" ] || return 1

	run_p4_as_perforce p4 logout > /dev/null 2>&1 || true

	if ! printf '%s\n' "$password" | run_p4_as_perforce p4 login > /dev/null 2>&1; then
		return 1
	fi

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

if [ -n "${CURRENT_PASSWORD}" ]; then
	write_p4config "${CURRENT_PASSWORD}"
fi

if [ -f "${ROTATE_MARKER}" ]; then
	exec 9>"${LOCK_FILE}"
	if flock -n 9; then
		if [ -f "${ROTATE_MARKER}" ]; then
			NEW_PASSWORD="$(/usr/local/bin/generate-password.sh 16)"

			if run_p4_as_perforce p4 passwd <<EOF
${CURRENT_PASSWORD}
${NEW_PASSWORD}
${NEW_PASSWORD}
EOF
			then
				( umask 077; printf '%s\n' "${NEW_PASSWORD}" > "${PASSWORD_FILE}" )
				chmod 600 "${PASSWORD_FILE}"
				CURRENT_PASSWORD="${NEW_PASSWORD}"
				write_p4config "${CURRENT_PASSWORD}"
				rm -f "${ROTATE_MARKER}"
				echo "初回ローテーションを実施しました。" >&2
				echo "新しいsuperパスワードは次のファイルに保存されています: ${PASSWORD_FILE}" >&2

				# 変更後パスワードで再ログイン
				if ! login_with_password "${NEW_PASSWORD}"; then
					echo "ローテーション後のsuperユーザーログインに失敗しました。" >&2
					exit 1
				fi
			else
				echo "superユーザーのパスワード変更に失敗しました。" >&2
				exit 1
			fi
		fi
	else
		echo "superユーザーのパスワードローテーションは他のプロセスが実行中のため待機せず継続します。" >&2
	fi
fi

if [ -f /opt/perforce/.p4trust ]; then
	chown perforce:perforce /opt/perforce/.p4trust || true
	chmod 600 /opt/perforce/.p4trust || true
fi

if [ -f /opt/perforce/.p4tickets ]; then
	chown perforce:perforce /opt/perforce/.p4tickets || true
	chmod 600 /opt/perforce/.p4tickets || true
fi

exec /usr/bin/tail --pid="$(cat "/var/run/p4d.${P4NAME}.pid")" -F "${P4ROOT}/logs/log"