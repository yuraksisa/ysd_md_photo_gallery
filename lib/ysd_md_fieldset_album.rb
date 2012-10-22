require 'ysd-plugins' unless defined?Plugins::ModelAspect

module FieldSet
  #
  # It's a module which can be used to extend a class to manage an album of photos
  #
  module Album
      include ::Plugins::ModelAspect

      def self.included(model)
        model.property :album_name, String, :field => 'album_name', :length => 80
      end
      
      @album = nil
      
      #
      # Add a photo to the album
      #
      # @param [Hash] photo_data
      #   :photo_id
      #   :photo_name
      #   :photo_description
      #
      # @param [File] photo_file
      #
      def album_add_photo(photo_data, photo_file)
        
        if album = get_album
          album.add_or_update_photo(photo_data, photo_file)          
        end
        
      end
      
      #
      # Updates an album photo
      #
      def album_update_photo!(photo_data, photo_file)
      
        if album = get_album
          album.add_or_update_photo(photo_data, photo_file)
        end
      
      end
      
      #
      # Removes a photo from the album
      #
      def album_remove_photo!(photo_id)
        
        if album = get_album
          album.delete_photo(photo_id)
        end
      
      end

      #
      # Get the photos of the album
      #
      def album_photos
        
        photos = if album=get_album
                   album.photos
                 else
                   []
                 end
        
      end

      private
      
      #
      # Retrieve the album
      #
      def get_album
        
        if album_name.nil? or album_name.to_s.strip.length == 0
          raise 'You must initialize the album_name before accesing the album'
        end
        
        unless @album
          @album = Media::Album.get(album_name)
        end
        
        return @album
        
      end

  end #Photo
end #FieldSet
