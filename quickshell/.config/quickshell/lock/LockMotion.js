// Whether the pointer really moved on the lock screen (lock/LockContent.qml): a move counts as
// activity, which ends the idle lock's grace period (Lock.qml), only once it's more than `limit`
// px (Manhattan) from where the pointer first showed up. The pointer merely being there when
// the lock screen appears, or a hand brushing the touchpad, doesn't. Plain JavaScript, tested
// (tests/tst_lockmotion.qml).
.pragma library

// `start` is where it first showed up ({ x: -1 } until then), `point` where it is now.
function moved(start, point, limit) {
    return start.x >= 0 && Math.abs(point.x - start.x) + Math.abs(point.y - start.y) > limit;
}
