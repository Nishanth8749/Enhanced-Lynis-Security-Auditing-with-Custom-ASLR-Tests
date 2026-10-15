#!/bin/sh

#################################################################################
#
# Enhanced Lynis Custom Security Test
#
# Test        : CUST-0010
# OS          : Linux
# Description : Comprehensive ASLR configuration audit
#
#################################################################################

InsertSection "Custom tests - Comprehensive Linux ASLR Audit"

Register --test-no CUST-0010 --weight H --network NO \
    --category security \
    --description "Audit ASLR configuration and provide remediation guidance"

if [ "${SKIPTEST}" -eq 0 ]; then

    if [ "${OS}" = "Linux" ]; then

        ASLR_SOURCE="sysctl"

        ASLR_VALUE=$(sysctl -n kernel.randomize_va_space 2>/dev/null)

        if [ -z "${ASLR_VALUE}" ]; then
            ASLR_SOURCE="/proc"

            if [ -r /proc/sys/kernel/randomize_va_space ]; then
                ASLR_VALUE=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null)
            fi
        fi

        LogText "ASLR source: ${ASLR_SOURCE}"
        LogText "ASLR value: ${ASLR_VALUE}"

        case "${ASLR_VALUE}" in

            2)
                Display --indent 2 \
                    --text "- Full ASLR is enabled" \
                    --result "${STATUS_OK}" --color GREEN
                LogText "Result: ASLR is fully enabled"
            ;;

            1)
                Display --indent 2 \
                    --text "- Partial ASLR protection detected" \
                    --result "${STATUS_WARNING}" --color YELLOW
                LogText "Result: ASLR is partially enabled"

                ReportSuggestion "${TEST_NO}" \
                    "Set kernel.randomize_va_space=2 to enable full ASLR"
            ;;

            0)
                Display --indent 2 \
                    --text "- ASLR protection is disabled" \
                    --result "${STATUS_WARNING}" --color RED
                LogText "Result: ASLR is disabled"

                ReportWarning "${TEST_NO}" \
                    "Enable ASLR by setting kernel.randomize_va_space=2"
            ;;

            "")
                Display --indent 2 \
                    --text "- ASLR configuration could not be determined" \
                    --result "${STATUS_WARNING}" --color YELLOW
                LogText "Result: ASLR value unavailable"

                ReportSuggestion "${TEST_NO}" \
                    "Verify kernel ASLR support and inspect the sysctl configuration"
            ;;

            *)
                Display --indent 2 \
                    --text "- Invalid or unexpected ASLR value: ${ASLR_VALUE}" \
                    --result "${STATUS_WARNING}" --color YELLOW
                LogText "Result: Unexpected ASLR value detected"

                ReportSuggestion "${TEST_NO}" \
                    "Verify kernel.randomize_va_space and use a supported value"
            ;;

        esac

        if [ -r /etc/sysctl.conf ]; then
            if grep -Eq '^[[:space:]]*kernel\.randomize_va_space[[:space:]]*=' /etc/sysctl.conf; then
                LogText "ASLR configuration entry found in /etc/sysctl.conf"
            else
                LogText "No explicit ASLR setting found in /etc/sysctl.conf"
            fi
        fi

    else
        LogText "Result: ASLR test skipped because operating system is not Linux"
    fi

fi

WaitForKeyPress