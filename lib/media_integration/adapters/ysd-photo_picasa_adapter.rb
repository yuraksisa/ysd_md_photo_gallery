require "signet/oauth_2/client"
require 'picasa'

# 
# Using it:
# 
#  adapter = MediaIntegration::Adapters::PicasaAdapter.new('username',)
#  album = MediaIntegration::Album.new
#  album.name = 'name'
#  adapter.create_album(album)
#
module MediaIntegration

  module Adapters
    #
    # Picasa adapter for media integration
    #
    class PicasaAdapter

      attr_reader :user, :client_id, :client_secret, :refresh_token

      #
      # Constructor
      #
      def initialize(user_account, client_id, client_secret, refresh_token)
        @user = user_account
        @client_id = client_id
        @client_secret = client_secret
        @refresh_token = refresh_token
        @last_time = nil
        @access_token = nil
      end
      
      #
      # Get all albums
      #
      def get_albums
         client = Picasa::Client.new(user_id: user, access_token: access_token)
         albums = client.album.list.entries.map  do |item|
                     album = MediaIntegration::Album.new(self) 
                     update_album_data(item, album)
                     album
                   end
         return albums
      end
     
      #
      # Get an album with its photos
      #
      def get_photos(user_id, album_id)
         client = Picasa::Client.new(user_id: user, access_token: access_token)
         picasa_album = client.album.show(album_id)

         photos = []
         picasa_album.entries.each do |source_photo|
           photo = MediaIntegration::Photo.new(self)
           update_photo_data(source_photo, photo)
           photos << photo
         end

         return photos
      end
      
      #
      # Get a photo
      #
      def get_photo(user_id, album_id, photo_id)
        photos = get_photos(user_id, album_id)
        (photos.select { |photo| photo.id == photo_id }).first
      end

      #
      # Creates an album
      #
      def create_album(album)
        client = Picasa::Client.new(user_id: user, access_token: access_token)
        data = {}
        data[:title] = album.name
        data[:summary] = album.summary
        picasa_album = client.album.create(data)
        update_album_data(picasa_album, album)
        return album
      end

      #
      # Updates the album information
      #
      def update_album(album)
        client = Picasa::Client.new(user_id: user, access_token: access_token)
        data = {}
        data[:title] = album.name
        data[:summary] = album.summary
        picasa_album = client.album.update(album.id, data)
        update_album_data(picasa_album, album)                        
      end                  

      #
      # Deletes an album
      # 
      def delete_album(album)
        client = Picasa::Client.new(user_id: user, access_token: access_token)
        client.album.destroy(album.id)
      end

      #
      # Create a photo with metadata
      #
      def create_photo(photo)
        client = Picasa::Client.new(user_id: user, access_token: access_token)
        data = {}
        data[:title] = photo.name
        data[:summary] = photo.description
        data[:content_type] = photo.mime_type || 'image/jpeg'
        photo.file.rewind
        data[:binary] = photo.file.read
        picasa_photo = client.photo.create(photo.album.id, data)        
        update_photo_data(picasa_photo, photo)
      end      
      
      #
      # Post a photo to an album not including metadata
      #
      # @param file Represents an open file
      #
      def create_photo_no_metadata(photo)
        create_photo(photo)
      end

      #
      # Update a photo : File + metadata
      #
      def update_photo(photo)
        client = Picasa::Client.new(user_id: user, access_token: access_token)
        data = {}
        data[:title] = photo.name
        data[:summary] = photo.description
        data[:binary] = photo.file.read
        picasa_photo = client.photo.update_file(photo.album.id, photo.id, data)        
        update_photo_data(picasa_photo, photo) 
      end  

      # 
      # Update a photo : Only its metadata
      #
      def update_photo_only_metadata(photo)
        client = Picasa::Client.new(user_id: user, access_token: access_token)
        data = {}
        data[:title] = photo.name
        data[:summary] = photo.description
        picasa_photo = client.photo.update(photo.album.id, photo.id, data)        
        update_photo_data(picasa_photo, photo) 
      end      

      #
      # Update a photo : Only the file
      #
      def update_photo_no_metadata(photo)
        client = Picasa::Client.new(user_id: user, access_token: access_token)
        data = {}
        data[:binary] = photo.file.read
        picasa_photo = client.photo.update_file(photo.album.id, photo.id, data)        
        update_photo_data(picasa_photo, photo_data) 
      end

      #
      # Delete a photo 
      #
      def delete_photo(photo)
        client = Picasa::Client.new(user_id: user, access_token: access_token)
        picasa_photo = client.photo.destroy(photo.album.id, photo.id)
      end

      #
      # Get the image
      #
      def image_url_to_size(image_url, width, height)
      
        path = image_url
        size = [width, height].max
      
        if path_parts=image_url.match(/(.+)\/(.+)$/)
          path = "#{path_parts[1]}/s#{size}/#{path_parts[2]}"
        end
      
        return path
      
      end            

      private

      def access_token

        if @last_time.nil? or (DateTime.now.to_time - @last_time.to_time)/3600 > 0.5
          signet = Signet::OAuth2::Client.new(
            client_id: client_id,
            client_secret: client_secret,
            token_credential_uri: "https://www.googleapis.com/oauth2/v3/token",
            refresh_token: refresh_token)
          signet.refresh!
          # Use access token with picasa gem
          @access_token = signet.access_token
          @last_time = DateTime.now
        end

        return @access_token

      end
   
      def update_album_data(source, adapted_album)
        adapted_album.id = source.id
        adapted_album.user = source.user
        adapted_album.name = source.title
        adapted_album.summary = source.summary
        adapted_album.size = source.numphotos
        adapted_album.remaining = 2000 - adapted_album.size
        adapted_album.bytes_used = 0
        adapted_album.image_url = source.media.cover_photo_url
        adapted_album.thumbnail_url = source.media.thumbnails.first.url
      end

      def update_photo_data(source_photo, adapted_photo)
        adapted_photo.id = source_photo.id
        adapted_photo.version = source_photo.image_version
        adapted_photo.width = source_photo.width
        adapted_photo.height = source_photo.height
        adapted_photo.image_url = source_photo.media.cover_photo_url
        adapted_photo.name = source_photo.title
        adapted_photo.description = source_photo.media.description        
        adapted_photo.thumbnails = []
        source_photo.media.thumbnails.each do |source_thumbnail|
          adapted_photo_thumbnail = MediaIntegration::PhotoThumbnail.new(source_thumbnail.url, source_thumbnail.width, source_thumbnail.height)
          adapted_photo.thumbnails << adapted_photo_thumbnail
        end
      end

    end
  end
end

module Picasa
  module API
    class Photo < Base

      # Updates photo
      #
      # @param [String] album_id album id
      # @param [String] photo_id photo id
      # @param [Hash] options request parameters
      # @option options [String] :album_id album id that photo will be moved to
      # @option options [String] :title title of photo
      # @option options [String] :summary summary of photo
      # @option options [String] :timestamp timestamp of photo
      # @option options [String] :keywords
      # @option options [String] :etag updates only when ETag matches - protects before destroying other client changes
      #
      # @return [Presenter::Photo] the updated photo
      def update_file(album_id, photo_id, params = {})
        template = Template.new(:update_photo, params)
        headers = auth_header.merge({"Content-Type" => "multipart/related; boundary=\"#{params[:boundary]}\"",
                                     "If-Match" => params.fetch(:etag, "*")})

        if params.has_key?(:timestamp)
          params[:timestamp] = params[:timestamp].to_i * 1000
        end
        path = "/data/entry/api/user/#{user_id}/albumid/#{album_id}/photoid/#{photo_id}"
        response = Connection.new.patch(path: path, body: template.render, headers: headers)

        Presenter::Photo.new(response.parsed_response["entry"])
      end

    end
  end
end