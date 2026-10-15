#!/bin/sh

#################################################################################
#
# Enhanced Lynis Custom Security Test
#
# Test        : CUST-0010
# OS          : Linux
# Description : Check ASLR status with fallback and error handling
#
#################################################################################

InsertSection "Custom tests - Enhanced Linux ASLR Security"

Register --test-no CUST-0010 --weight M --network NO \
    --category security \
    --description "Check Linux ASLR status with fallback detection"

if [ "${SKIPTEST}" -eq 0 ]; then

    if [ "${OS}" = "Linux" ]; then

        ASLR_VALUE=$(sysctl -n kernel.randomize_va_space 2>/dev/null)

        if [ -z "${ASLR_VALUE}" ]; then
            if [ -r /proc/sys/kernel/randomize_va_space ]; then
                ASLR_VALUE=$(cat /proc/sys/kernel/randomize_va_space 2>/dev/null)
            fi
        fi

        LogText "ASLR: kernel.randomize_va_space=${ASLR_VALUE}"

        case "${ASLR_VALUE}" in

            2)
                Display --indent 2 \
                    --text "- Full ASLR randomization is enabled" \
                    --result "${STATUS_OK}" --color GREEN
                LogText "Result: Full ASLR is enabled"
            ;;

            1)
                Display --indent 2 \
                    --text "- ASLR is partially enabled" \
                    --result "${STATUS_WARNING}" --color YELLOW
                LogText "Result: Partial ASLR detected"
                ReportSuggestion "${TEST_NO}" \
                    "Set kernel.randomize_va_space to 2 for full ASLR"
            ;;

            0)
                Display --indent 2 \
                    --text "- ASLR is disabled" \
                    --result "${STATUS_WARNING}" --color RED
                LogText "Result: ASLR is disabled"
                ReportWarning "${TEST_NO}" \
                    "ASLR is disabled. Set kernel.randomize_va_space to 2"
            ;;

            "")
                Display --indent 2 \
                    --text "- ASLR status could not be read" \
                    --result "${STATUS_WARNING}" --color YELLOW
                LogText "Result: Unable to read ASLR configuration"
                ReportSuggestion "${TEST_NO}" \
                    "Check kernel support and permissions for reading the ASLR setting"
            ;;

            *)
                Display --indent 2 \
                    --text "- Unexpected ASLR configuration value: ${ASLR_VALUE}" \
                    --result "${STATUS_WARNING}" --color YELLOW
                LogText "Result: Unexpected ASLR value: ${ASLR_VALUE}"
            ;;

        esac

    else
        LogText "Result: ASLR test skipped because operating system is not Linux"
    fi

fi

WaitForKeyPress