#Peek

Peek is a simple Briq that has no installation parameters.  

Once installed, it will place a new menu item 'Peek' in to top menu bar. If you navigate to this page, and then open your browser development tools you will be able to see various messages are are sent around the HouseMon messaging bus.  

A recent addition was the simple debug API interface. You can now turn on/off the debug flag from within the Administration panel. This will allow you to see messages on the server console.  

A feature to be added shortly will be a message filter to allow some control over the peeking of messages, so check back soon.

*Note: Some messages contain information about objects that can sometimes reference themselves. This is called a circular reference and for simplicity's sake, these type of messages are not displayed in the web debug console.*