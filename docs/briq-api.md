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

