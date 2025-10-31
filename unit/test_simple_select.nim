## Simple test to verify select operations work

import std/strformat
import chronos
import ../../src/nimsync

proc testBasicSelect() {.async.} =
  echo "🧪 Testing basic select operations..."

  var ch1 = newChannel[int](10, ChannelMode.SPSC)

  # Send to first channel (non-blocking)
  if not trySend(ch1, 42):
    echo "❌ Failed to send to channel"
    return

  echo "📤 Sent 42 to ch1"

  # Receive from ch1
  var value: int
  if tryReceive(ch1, value):
    echo fmt"📊 Received: {value}"

    if value == 42:
      echo "✅ Test PASSED!"
    else:
      echo "❌ Test FAILED!"
  else:
    echo "❌ Failed to receive"

proc main() {.async.} =
  await testBasicSelect()

when isMainModule:
  waitFor main()