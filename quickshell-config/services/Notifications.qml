pragma Singleton

import QtQuick

QtObject {
    id: root
    
    // Placeholder notification service
    // Can be expanded later if needed
    
    signal notificationReceived(string summary, string body, string icon)
    
    function sendNotification(summary, body, icon) {
        console.log("Notification:", summary, body)
        notificationReceived(summary, body, icon || "")
    }
}
