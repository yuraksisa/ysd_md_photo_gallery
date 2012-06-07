require 'rubygems'
require './ysd-photo_collection'
require './ysd-photo_picasa_adapter'
require 'gdata19'

PhotoCollection.setup('user' => 'my.user', 'password' => 'my.password', 'adapter' => 'picasa')

album=PhotoCollection::Album.new
album.name='My Album'
album.summary='My album'

photo=PhotoCollection::Photo.new
photo.album=album
photo.name='name'
photo.description='description'
photo.file=File.new('')
album.photos<<photo

album.save

