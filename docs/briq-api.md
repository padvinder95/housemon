######Updated: 2013-07-12 - additional debug helpers support

#Briq API

Even though Briq development is in an early stage it is still possible to define
a light-weight api to help developers. 
This first version document is just to get the ball rolling and defines some aspects of
that api that are being used by the revised admin module.

##Module exports
Like most node module development, our Briq needs to export something public to 
the outside world. The first object that Housemon looks for in a Briq is
an 'info' object. This object is responsible for 'describing' the Briq to the housemon 
system and as such contains a number of interesting items.
 
The first of these items are properties that help to support additional information
within the Admin module, these are:

-  version *(string)*  

   This property supplies version information, it is displayed in the revised 'admin' module.
   If supplied it is displayed next to the modules name, and also as a tooltip over the Briq name in the list of available Briqs.

-  name *(string) REQUIRED* 
   
   This is the name of your briq.*

-  description *(string)*  
   
   Some text that briefly describes your briq. Displayed in the Admin modules 'Briqs' column against the name.
   Its is also used on the Briq installation page if not 'descriptionHtml' is available.

-  descriptionMd *(string)*  

   This description can contain Markdown, and gets displayed on the Briq information panel when installing. 

-  author *(string)*  

   The name of the Briq author, displayed in top right of admin panel, and additionally in the tooltip over the Briq name in the Available Briqs column.

-  authorUrl *(string)*  

   A url that can provide additional data about the author, will decorate the author name on the Briq installation panel.

-  briqUrl *(string)*  

   A url to allow the author to supply more information about the briq itself. This is displayed in an [about] link on the Briq installation panel, and additionally as a link
   next to the Briq description on the Available Briq's column.

##Simple Debugging Support

If the following methods are available within your Briq Class, they can be used by the admin module (and any other modules that want to make use of them).

-  bobInfo: (bob)

   object:bob
   
   Called upon Bob Instantiation if present, passing in the following structure:
     
   >     {"briq_id":"0","key":"briq:briqparam1","id":0}
  
   where:
	*  briq_id is an incrementing id specific to this briq type.
	*  key is a canonical list of briq name and briq 'install' parameters.
	*  id is an incrementing id specific to this 'instance' of the briq object (bob).


-  setDebug: (flag)

   boolean: flag

   If this method is present within your Briq, is called after constructor(), but before inited(), but only
   if a debug flag is present within the global briq configuration file /briqs.json - see below
   This method can also be called interactively by the Admin module.

-  setDebug: (flag)

   boolean:flag

   This method can be called interactively by the Admin module if it is present within your briq (bob).

- dump: ()

  If present, can be called interactively by the Admin module to dump internals of your running bob for basic debug purposes. Should return a string.


##Global Briq Configuration file.

Upon startup, HouseMon will look for a *briqs.json* configuration file within the application root folder. Presently the use of this file is
limited to providing a debug flag specific to a bob instance, and configuration objects specific to matching regex on bob key. The format is as follows:

###briqs.json
  
>     {
       "help" : "Information about this configuration file can be found in briqs-api.md in the docs",
       "debug": {
         "0":false
       },
       "config": {
         "yourbriq.*": {"prop1":1,"prop2":2},
         "yourbriq:param1.*": {"prop2":20}
       }
      }

The debug key holds a child object of id/value pairs. The boolean value representing the value to be passed into the *.setDebug()* method of the bob once instantiated.
In the example above, the fictional bob with id=0 will be passed the value of *false* to the *setDebug()* method if present. 

The config key holds a child object of key(regex)/object pairs. The key(regex) field will be matched to the key of a bob, and if a match is found, the object will be passed to a
*setConfig()* function of the bob if present.

Keys are matched in order presented within the *briqs.json* file. It is possible to target a base config using briq name, and subsequent per-instance configurations
using multiple config entries as show above (where bobs with param1 present, will be passed and object with overrides for prop2),
in this case your bob's *setConfig* will be called multiple times.


 







