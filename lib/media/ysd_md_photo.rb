require 'stringio' unless defined?StringIO
require 'data_mapper' unless defined?DataMapper

module Media

  #
  # Photo
  #
  class Photo
    include DataMapper::Resource

      storage_names[:default] = 'media_photos'

      property :id, Serial, :key => true

      property :name, String, :length => 255
      property :description, Text
      property :width, Integer
      property :height, Integer

      belongs_to :album

      property :external_photo, String, :length => 255, :unique_index => :external_photo_index

      property :photo_url_full, String, :length => 255
      property :photo_url_medium, String, :length => 255
      property :photo_url_small, String, :length => 255
      property :photo_url_tiny, String, :length => 255
      
      #
      # Find a photo by its external id
      #
      def self.find_by_external_id(external_album_id, external_photo_id)
        
        first(:album => { :external_album => external_album_id},
        	    :external_photo => external_photo_id)

      end

      #
      # Store the photo
      #
      # @param [File] photo_file
      #
      def store_photo(photo_file)
      
        img_file = photo_file
        if img=adjust_image(photo_file,{:width => self.album.width, :height => self.album.height})
          img_file = StringIO.new(img.to_blob)
        end
        
        storage_album = album.adapted_album    
        adapter = storage_album ? storage_album.adapter : album.media_storage.get_adapter

        storage_photo = MediaIntegration::Photo.new(adapter)           
        storage_photo.id = self.external_photo
        storage_photo.name = self.name
        storage_photo.description = self.description
        storage_photo.file = img_file
                 
        unless storage_album 
          storage_album = MediaIntegration::Album.new(adapter)
          storage_album.name = album.name       
          storage_photo.album = storage_album
          storage_album.photos << storage_photo
          storage_album.save
          p "saving album : #{storage_album.id}"
          album.external_album = storage_album.id
          album.save
        else
          storage_photo.album = storage_album
          storage_photo.save(true)
        end
        
        update(:external_photo => storage_photo.id,
               :width => storage_photo.width,
               :height => storage_photo.height,
               :photo_url_full => storage_photo.image_url,
               :photo_url_tiny => storage_photo.thumbnails.first.thumbnail_url,
               :photo_url_small => storage_photo.thumbnails[1].thumbnail_url,
               :photo_url_medium => storage_photo.thumbnails.last.thumbnail_url)

      end 

      def destroy
         
        if external_photo and not external_photo.empty?
          delete_photo_file!
        end

        super

      end

      def get_image_url(width, height)

        album.media_storage.get_adapter.image_url_to_size(photo_url_full, width, height)

      end

      private

      #
      # Delete the photo_file
      #
      def delete_photo_file!

        if external_photo = get_external_photo
          external_photo.delete
        end

      end

      # Adjusts an file applying options
      #
      # @param [File]
      #   The file which represents the photo
      # @param [Hash]
      #   The adjust options
      #
      #   :width, :height
      # 
      #
      def adjust_image(file, options)
    
        img = Magick::Image.from_blob(file.read).first      
        if img
          if options.has_key?(:width) and options[:width] > 0
            if options.has_key?(:height) and options[:height] > 0
              img = img.resize_to_fit(options[:width], options[:height])
            else
              img = img.resize_to_fit(options[:width])
            end
          end
        end
       
        return img
      
      end 

      #
      # Get the external photo
      #
      def get_external_photo

        if adapted_album = album.adapted_album
          (adapted_album.photos.select { |photo| photo.id == external_photo }).first
        end

      end

  end
end