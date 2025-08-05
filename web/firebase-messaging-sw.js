// Import scripts from Firebase
importScripts('https://www.gstatic.com/firebasejs/10.3.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.3.1/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyDxAMoGinRtFx1rUSLq-EIdS89rrtZqTAs",
  authDomain: "tapalert-166b2.firebaseapp.com",
  projectId: "tapalert-166b2",
  messagingSenderId: "37217913542",
  appId: "1:37217913542:web:198a3b2d66befb604e65c7",
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();
