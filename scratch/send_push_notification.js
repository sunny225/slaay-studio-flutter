/**
 * Firebase Cloud Messaging (FCM) Push Notification Script for SLAAY App Backend Integration
 * 
 * Instructions:
 * 1. Install Firebase Admin SDK: npm install firebase-admin
 * 2. Download your Firebase Service Account JSON credentials from:
 *    Firebase Console -> Project Settings -> Service Accounts -> Generate New Private Key
 * 3. Save it as `serviceAccountKey.json` in the same directory as this script.
 * 4. Run the script: node send_push_notification.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Target device FCM token (Copy this token from the Merchant Dashboard screen inside the app!)
const registrationToken = 'PASTE_COPIED_DEVICE_FCM_TOKEN_HERE';

// Define push notification payloads for different use cases
const notificationTemplates = {
  // 🛒 Use Case 1: Abandoned Cart Reminders
  abandonedCart: {
    notification: {
      title: 'Items Left In Cart! 🛒',
      body: 'Your handcrafted linen shirt is waiting for you. Complete your order today for 10% off!'
    },
    data: {
      type: 'abandoned_cart', // Directs the app to navigate to the Cart Screen on tap
      click_action: 'FLUTTER_NOTIFICATION_CLICK' // Triggers foreground callbacks on Android/iOS
    }
  },

  // ✨ Use Case 2: New Drops / Launches
  newDrop: {
    notification: {
      title: 'New Drops Live! ✨',
      body: 'The highly anticipated Pastel Cotton Silk collection is now live. Tap to shop now!'
    },
    data: {
      type: 'new_drop', // Directs the app to navigate to the New Drops Screen on tap
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    }
  },

  // 🎉 Use Case 3: Payments / Order Confirmations
  paymentConfirmed: {
    notification: {
      title: 'Payment Successful! 🎉',
      body: 'Thank you! Your payment of ₹2,499 was successfully received. Track your order status in profile.'
    },
    data: {
      type: 'payment', // Directs the app to navigate to the Profile/Order history Screen on tap
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    }
  },

  // 📢 Use Case 4: General Broadcast / Promotion Campaigns
  promoBroadcast: {
    notification: {
      title: 'Mid-Summer Sale! ☀️',
      body: 'Enjoy up to 50% off sitewide on premium ethnic wear. Limited period offer!'
    },
    data: {
      type: 'promo',
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    }
  }
};

/**
 * Send FCM push notification to a specific device
 * @param {string} token Target Device Registration Token
 * @param {object} payload Message payload configuration
 */
async function sendPushNotification(token, payload) {
  if (token === 'PASTE_COPIED_DEVICE_FCM_TOKEN_HERE' || !token) {
    console.error('Error: Please copy the active Device FCM Token from the profile dashboard and paste it into the script.');
    process.exit(1);
  }

  // Construct message payload matching FCM structure
  const message = {
    token: token,
    notification: {
      title: payload.notification.title,
      body: payload.notification.body
    },
    data: payload.data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel', // Direct mapping to the local notifications channel
        sound: 'default'
      }
    },
    apns: {
      headers: {
        'apns-priority': '10'
      },
      payload: {
        aps: {
          alert: {
            title: payload.notification.title,
            body: payload.notification.body
          },
          sound: 'default',
          badge: 1
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Push notification dispatched successfully!');
    console.log('Message ID:', response);
  } catch (error) {
    console.error('Error sending push notification:', error);
  } finally {
    process.exit(0);
  }
}

// Trigger test notification (Choose template: abandonedCart, newDrop, paymentConfirmed, promoBroadcast)
const selectedTemplate = notificationTemplates.abandonedCart;
sendPushNotification(registrationToken, selectedTemplate);
