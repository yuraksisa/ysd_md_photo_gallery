require 'rubygems'
require './ysd-photo_collection'
require './ysd-photo_picasa_adapter'
require 'gdata19'

adapter = MediaIntegration::Adapters::PicasaAdapter('my-account', 'my-password')
media_connection = MediaIntegration::MediaConnection.new(adapter)

album=MediaIntegration::Album.new(adapter)
album.name='My Album'
album.summary='My album'

photo=MediaIntegration::Photo.new(adapter)
photo.album=album
photo.name='name'
photo.description='description'
photo.file=File.new('')
album.photos<<photo

album.save

