#!/usr/bin/env bash
set -euo pipefail

jq -r '
  def fmt_tok:
    if . >= 1000000 then "\((. / 100000 | floor) / 10)M"
    elif . >= 1000 then "\((. / 100 | floor) / 10)k"
    else "\(.)"
    end;

  (.model.display_name // "unknown") as $model |
  (.cycle_mode // "") as $mode |
  (.context_window.used_percentage // 0) as $pct |
  (.context_window.context_window_size // 0) as $win |
  (.context_window.current_usage.input_tokens // 0) as $in |
  (.context_window.current_usage.cache_read_input_tokens // 0) as $cr |
  (.context_window.current_usage.cache_creation_input_tokens // 0) as $cc |
  ($in + $cr + $cc) as $turn_in |
  (if $turn_in > 0 then (($cr * 100 / $turn_in) | floor) else 0 end) as $hit |

  "\u001b[36m\($model)\u001b[0m"
  + (if $mode != "" then " \u001b[2m[\($mode)]\u001b[0m" else "" end)
  + " | "
  + (if $pct >= 80 then "\u001b[31m" elif $pct >= 50 then "\u001b[33m" else "\u001b[32m" end)
  + "ctx \(($pct * 10 | floor) / 10)%\u001b[0m"
  + (if $win > 0 then " \u001b[2m(\($win | fmt_tok))\u001b[0m" else "" end)
  + " | "
  + "cache \u001b[35m\($cr | fmt_tok)\u001b[0m"
  + (if $turn_in > 0 then " (\($hit)%)" else "" end)
'
