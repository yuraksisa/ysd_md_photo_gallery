require 'ysd-plugins' unless defined?Plugins::ModelAspect

module FieldSet

  #
  # It's a module which can be used to extend a class to manage an album of photos
  #
  module Album
      include ::Plugins::ModelAspect

      def self.included(model)
      
        if model.respond_to?(:property)
          model.property :album_name, String, :field => 'album_name', :length => 40
          model.property :photo_path, String, :field => 'photo_path', :length => 80 # Reference to the main photo of the album
          model.property :photo_url_tiny, String, :field => 'photo_url_tiny', :length => 256 # Reference to the main photo of the album
          model.property :photo_url_small, String, :field => 'photo_url_small', :length => 256 # Reference to the main photo of the album
          model.property :photo_url_medium, String, :field => 'photo_url_medium', :length => 256 # Reference to the main photo of the album
          model.property :photo_url_full, String, :field => 'photo_url_full', :length => 256 # Reference to the main photo of the album          
        end

        #if model.respond_to?(:before)
        #  model.before :save do |element|
        #     element.album_name ||= element.default_album_name
        #  end
        #end
      

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
        
        album.add_or_update_photo(photo_data, photo_file) if album         
        
      end
      
      #
      # Updates an album photo
      #
      def album_update_photo!(photo_data, photo_file)
     
        album.add_or_update_photo(photo_data, photo_file) if album
        
      end
      
      #
      # Removes a photo from the album
      #
      def album_remove_photo!(photo_id)
        
        album.delete_photo(photo_id) if album
      
      end

      #
      # Get the photos of the album
      #
      def album_photos
        
        photos = if album
                   album.photos
                 else
                   []
                 end
        
      end
      
      #
      # Retrieve the album
      #
      def album
        
        if @album.nil?
          @album = Media::Album.get(album_name || default_album_name)
        end

        return @album
        
      end
      
      #
      # Default album name
      #
      def default_album_name

        if respond_to?(:resource_info)
          return resource_info
        else
          raise "The element class must supply resource_info method"
        end

      end

  end #Photo
end #FieldSet
