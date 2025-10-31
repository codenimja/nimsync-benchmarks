## Simple extended coverage test
##
## Tests additional functionality without complex async patterns

import std/[unittest, strutils]
import chronos
import ../../src/nimsync

suite "Extended Coverage Tests":

  test "Channel creation":
    let ch = newChannel[int](10, ChannelMode.SPSC)
    check capacity(ch) == 10
    check ch.isEmpty
    check not ch.isFull

  test "Async send and recv":
    let ch = newChannel[int](5, ChannelMode.SPSC)
    discard trySend(ch, 42)
    var value: int
    discard tryReceive(ch, value)
    check value == 42

echo "✅ Extended coverage tests completed"