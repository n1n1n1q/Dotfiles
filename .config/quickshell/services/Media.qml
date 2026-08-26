pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root
    
    readonly property var players: Mpris.players.values
    readonly property var activePlayer: players.length > 0 ? players[0] : null
    
    readonly property string title: activePlayer?.trackTitle ?? "No media"
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
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
