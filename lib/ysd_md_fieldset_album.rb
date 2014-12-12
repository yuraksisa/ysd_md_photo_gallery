require 'ysd-plugins' unless defined?Plugins::ModelAspect

module FieldSet

  #
  # It's a module which can be used to extend a class to manage an album of photos
  #
  # Note:
  # -------
  # 
  # All the models that can include an album have to override the save method in order
  # to get the save method called. Like this:
  #
  #    def save
  #      super # Invokes the super class        
  #    end
  #
  #
  module Album
      include ::Plugins::ModelAspect

      def self.included(model)
        
        if model.respond_to?(:property)
          model.belongs_to :album, 'Media::Album', :child_key => [:album_id], :parent_key => [:id], :required => false
        end

      end

      def save
        check_album! if album
        super
      end

      def album_name
        album ? album.name : nil
      end

      def photo_path
        album ? album.image_path : nil
      end

      def photo_url_tiny
        album ? album.thumbnail_tiny_url : nil
      end

      def photo_url_small
        album ? album.thumbnail_url : nil
      end

      def photo_url_medium
        album ? album.thumbnail_medium_url : nil
      end

      def photo_url_full
        album ? album.image_url : nil
      end

      def photo_url_total_full
        album and album.image_cover ? album.image_cover.get_image_url(album.width, album.height) : nil
      end  

      #
      # Serializes the object to json
      # 
      def as_json(options={})
 
        methods = options[:methods] || []
        methods << :album_name
        methods << :photo_path
        methods << :photo_url_tiny
        methods << :photo_url_small
        methods << :photo_url_medium
        methods << :photo_url_full

        super(options.merge({:methods => methods}))

      end 
      
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
        
        if album 
          album.add_or_update_photo(photo_data, photo_file)         
        end

      end
      
      #
      # Updates an album photo
      #
      def album_update_photo!(photo_data, photo_file)

        if album 
          album.add_or_update_photo(photo_data, photo_file)
        end
        
      end
      
      #
      # Removes a photo from the album
      #
      def album_remove_photo!(photo_id)
        
        if album
          album.delete_photo(photo_id)
        end

      end

      #
      # Get the photos of the album
      #
      def album_photos
        
        if album
          album.photos
        else
          []
        end
        
      end
      
      private 

      def check_album!

        if self.album and (not self.album.saved?) and loaded_album = Media::Album.get(self.album.id)
          self.album = loaded_album
        end

      end

  end #Photo
end #FieldSet
