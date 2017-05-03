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

      property :photo_url_full, String, :length => 255
      property :photo_url_medium, String, :length => 255
      property :photo_url_small, String, :length => 255
      property :photo_url_tiny, String, :length => 255

      #
      # Store the photo
      #
      # @param [File] photo_file
      # @params [String] filename
      #
      def store_photo(photo_file, filename)
      
        img = Magick::Image.ping(photo_file.path).first
        image_width = img.columns
        image_height = img.rows

        adapter = album.get_adapter

        if photo_url_full.nil? || photo_url_full.empty?
          result = adapter.create_photo(album.id, id, photo_file, filename)
        else
          result = adapter.update_photo(album.id, id, photo_file, filename)
        end  

        update(width: image_width,
               height: image_height,
               photo_url_full: result[:image_url],
               photo_url_tiny: result[:image_url_tiny],
               photo_url_small: result[:image_url_small],
               photo_url_medium: result[:image_url_medium])

      end 

      #
      # Destroy the photo
      #
      def destroy
         
        if photo_url_full.nil? || photo_url_full.empty?
          adapter = album.get_adapter
          adapter.delete_photo(album.id, id)
        end

        super

      end

      def get_image_url(width, height)

        photo_url_full

      end

  end
end