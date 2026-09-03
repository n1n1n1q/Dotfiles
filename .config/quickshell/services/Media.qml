pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    // Which player the UI is focused on. Clamped to the live list so players
    // appearing / disappearing never leaves a stale index.
    property int selectedIndex: 0
    readonly property var activePlayer: players.length > 0
        ? players[Math.min(selectedIndex, players.length - 1)] : null

    function cyclePlayer() {
        if (players.length > 1)
            selectedIndex = (Math.min(selectedIndex, players.length - 1) + 1) % players.length;
    }

    // Seek to an absolute position (seconds, same unit as `length`).
    function seek(pos) {
        if (activePlayer && (activePlayer.positionSupported ?? false))
            activePlayer.position = Math.max(0, pos);
    }

    readonly property string title: activePlayer?.trackTitle ?? "No media"
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false

    // --- Playback position / length ----------------------------------------
    //
    // MPRIS never pushes smooth position updates, so a Timer re-polls while
    // playing (poking `positionChanged()` makes Quickshell re-interpolate).
    //
    // Firefox/Zen also stops advertising the track length after a manual
    // seek: `lengthSupported` flips to false and `length` starts tracking
    // `position`, so a naive `position / length` pins at 1.0 - the "progress
    // ring fills right up" bug (and if you gate on `lengthSupported`, it
    // vanishes instead). Work around it by remembering the last length seen
    // while it *was* supported and falling back to that until the player
    // recovers (usually on the next track).

    readonly property string trackKey: (activePlayer?.trackTitle ?? "")
        + "␟" + (activePlayer?.trackArtist ?? "")

    property real cachedLength: 0

    // Remember any positive length the player reports. `lengthSupported` is the
    // strong signal (the track genuinely carries mpris:length), but some
    // players never set it while still reporting a usable `length`, so a bare
    // `length > 0` is enough to cache — the post-seek Firefox case (where
    // `length` starts shadowing `position`) is still caught because by then we
    // already have a real cachedLength from before the seek.
    function cacheLength() {
        if (!activePlayer)
            return
        if (activePlayer.lengthSupported && activePlayer.length > 0)
            cachedLength = activePlayer.length
        else if (cachedLength <= 0 && activePlayer.length > 0)
            cachedLength = activePlayer.length
    }

    onActivePlayerChanged: { cachedLength = 0; cacheLength() }
    onTrackKeyChanged: { cachedLength = 0; cacheLength() }

    readonly property real length: {
        if (!activePlayer)
            return 0
        if (activePlayer.lengthSupported && activePlayer.length > 0)
            return activePlayer.length
        if (cachedLength > 0)
            return cachedLength
        return activePlayer.length > 0 ? activePlayer.length : 0
    }
    readonly property real position: activePlayer?.position ?? 0
    // For *display* we only need a length and a sane position; positionSupported
    // is often false for a beat right after a track change and shouldn't blank
    // the ring / bar. It still gates whether the seek bar is draggable.
    readonly property bool hasProgress: length > 0 && (activePlayer?.positionSupported ?? false)
    readonly property real progress: length > 0
        ? Math.max(0, Math.min(1, position / length)) : 0

    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onLengthChanged() { root.cacheLength() }
        function onLengthSupportedChanged() { root.cacheLength() }
        function onMetadataChanged() { root.cacheLength() }
        function onPositionSupportedChanged() { root.cacheLength() }
    }

    // MPRIS never pushes smooth position updates — re-poke while playing so
    // Quickshell re-interpolates. Only runs while actually playing (paused
    // position is static), like end-4's — and it self-stops chasing a late
    // length once one is cached, so a playing track costs one poke a second.
    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying
        onTriggered: {
            root.activePlayer?.positionChanged()
            if (root.cachedLength <= 0)
                root.cacheLength()
        }
    }

    readonly property bool canPlay: activePlayer?.canPlay ?? false
    readonly property bool canPause: activePlayer?.canPause ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property string identity: activePlayer?.identity ?? ""

    function play() {
        if (activePlayer && activePlayer.canPlay) {
            activePlayer.play()
        }
    }

    function pause() {
        if (activePlayer && activePlayer.canPause) {
            activePlayer.pause()
        }
    }

    function togglePlayPause() {
        if (activePlayer && activePlayer.canTogglePlaying) {
            activePlayer.togglePlaying()
        }
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) {
            activePlayer.next()
        }
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) {
            activePlayer.previous()
        }
    }

    Component.onCompleted: {
        console.log("Media service initialized")
        console.log("Available players:", players.length)
        if (activePlayer) {
            console.log("Active player:", activePlayer.identity)
        }
    }
}
