YSD_MD_PHOTO_GALLERY
====================

<p>Media gallery management. The media storage is managed using adapters. There is one adapter implemented in this moment, the picasa adapter, though more adapters can be defined.</p>

<p>The main component of the API is the Media::Album class. It allow to create a media album an media resources</p>

<h2>Creating a new album and adding photos</h2>

<p>The following example will create an album and store one photo on it.</p>
<p>Check that the configuration variables are set before executing it.</p>

<pre>
 require 'ysd_md_photo_gallery'
 album = Media::Album.new({:name => 'my_album', :description => 'album description', :width => 640, :height=>480})
 album.add_or_update_photo({:photo_name => 'the photo name', :photo_description => 'photo description'}, File.open("photo path"))
</pre>

<h2>Adding photos to an album</h2>

<h2>Configuration</h2>

<p>Default configuration parameters are defined through the following system configuration variables</p>

<ul>
  <li>photo_default_adapter: The default photo adapter</li>
  <li>photo_default_account: The default photo account</li>
</ul>

<p>They can also be defined for any album, in the album definition, using the attributes adapter and account</p>

<h3>Adapters</h3>

<p>PhotoCollection::PicasaAdapter represents the picasa adapter</p>