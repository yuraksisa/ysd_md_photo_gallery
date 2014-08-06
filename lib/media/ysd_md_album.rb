require 'stringio' unless defined?StringIO
require 'data_mapper' unless defined?DataMapper
require 'ysd_md_externalserviceaccount' unless defined?(Integration::ExternalServiceAccount)
require 'ysd_md_configuration' unless defined?(SystemConfiguration::Variable)

module Media
  
  #
  # It represents an Album
  #
  class Album
    include DataMapper::Resource
    
    storage_names[:default] = 'media_albums'

    property :id, Serial
    property :name, String, :field => 'name', :length => 100
    property :prefix, String, :field => 'prefix', :length => 100
    property :description, String, :field => 'description', :length => 255
        
    property :width, Integer, :field => 'width'    # The element width
    property :height, Integer, :field => 'height'  # The element height
    
    property :external_album, String, :field => 'external_album', :length => 50 # The external album 

    belongs_to :media_storage, 'Media::Storage',
      :child_key => ['storage_name'], :parent_key => ['name']

    has n, :photos, 'Media::Photo', :constraint => :destroy 

    property :remaining, Integer, :field => 'remaining' # Remaining number of items
    property :bytes_used, Integer, :field => 'bytes_used' # The total space used

    has 1, :album_cover
        
    #
    # Saves the album
    #
    def save
      
      if self.new?
        unless media_storage
          if default_storage = SystemConfiguration::Variable.get_value('media.default_storage')
            self.media_storage = Media::Storage.get(default_storage)
          end
        end
      end

      if self.media_storage and (not self.media_storage.saved?)
        self.media_storage = Media::Storage.get(self.media_storage.name)
      end
    
      begin 
        super
        if name.nil? and prefix
          update(:name => "#{prefix}#{id}")
        end
      rescue DataMapper::SaveFailureError => error
             p "Error saving album #{error} #{self.inspect} #{self.errors.inspect}"
             raise error 
      end

    end

    #
    # Add a photo to an album
    #
    # @param [Hash] photo_data
    #   :photo_id
    #   :photo_name
    #   :photo_description
    #
    # @param [File] photo_file
    #
    # @return [MediaIntegration::Photo]
    #   The photo with the updated information
    #
    def add_or_update_photo(photo_data, photo_file)

      if photo_data.has_key?(:photo_id)
        photo = Media::Photo.get(photo_data[:photo_id])
      else  
        photo = Media::Photo.create({:album => self, 
             :name => photo_data[:photo_name],
             :description => photo_data[:photo_description]})
      end

      photo.store_photo(photo_file)

      return photo
    
    end

    #
    # Gets the adapted album, the real album which stores the images
    #
    def adapted_album
      get_external_album
    end
    
    #
    # Retrieve the information from the external album and update the album information
    #
    def synchronize_data
      
      if external_album = get_external_album
        self.size = external_album.size
        self.remaining = external_album.remaining
        self.bytes_used = external_album.bytes_used
        self.image_url = external_album.image_url
        self.thumbnail_url = external_album.thumbnail_url
        self.save
      end
    
    end
       
    #
    # Import photos from the external album
    #                
    def import_photos

      if external_album = get_external_album

        external_storage_photos = external_album.photos

        # Add the photos that exist in the remote storage and not in the album
        external_storage_photos.each do |photo|
          unless the_photo = Photo.find_by_external_id(photo.album.id, photo.id)
            Photo.create(:album => self,
                         :external_photo => photo.id,
                         :name => photo.name,
                         :description => photo.description,
                         :width => photo.width,
                         :height => photo.height,
                         :photo_url_full => photo.image_url,
                         :photo_url_medium => photo.thumbnails.last.thumbnail_url,
                         :photo_url_small => photo.thumbnails[1].thumbnail_url,
                         :photo_url_tiny => photo.thumbnails.first.thumbnail_url
                         )
          end
        end

        # Remove the photos that exist in the album but no longer exists in the remote storage

        #photos.each do |photo|
        #
        #  unless (external_storage_photos.select { |external_photo| external_photo.id == photo.external_photo and external_photo.album.id == photo.album.external_album}).empty?
        #    photo.destroy
        #  end
        #
        #end

      end

    end

    #
    # Get the album cover photo URL
    #
    def image_url
      album_cover ? album_cover.photo.photo_url_full : photos.size > 0 ? photos.first.photo_url_full : nil
    end

    #
    # Get the image path
    #
    def image_path
      photo = album_cover ? album_cover.photo : photos.first
      "/album/#{id}/photo/#{photo.id}"
    end

    #
    # Get the album cover photo URL in thumbnail size (medium)
    #
    def thumbnail_medium_url
      album_cover ? album_cover.photo.photo_url_medium : photos.size > 0 ? photos.first.photo_url_medium : nil
    end

    #
    # Get the album cover photo URL in thumbnail size (tiny)
    #
    def thumbnail_tiny_url
      album_cover ? album_cover.photo.photo_url_tiny : photos.size > 0 ? photos.first.photo_url_tiny : nil
    end

    #
    # Get the album cover photo URL in thumbnail size (small)
    #
    def thumbnail_url
      album_cover ? album_cover.photo.photo_url_small : photos.size > 0 ? photos.first.photo_url_small : nil
    end

    #
    # Get the album size (number of elements)
    #
    def size
      photos.size
    end

    #
    # Serializes the object to json
    # 
    def as_json(options={})
 
      methods = options[:methods] || []
      methods << :image_url
      methods << :thumbnail_url
      methods << :size
  
      relationships = options[:relationships] || {}
  
      super(options.merge({:relationships => relationships, :methods => methods}))

    end 

    private

    #
    # Gets the external album (used to manage the photos)
    #
    def get_external_album
     
      unless defined?(@_external_album)
        media_connection = MediaIntegration::MediaConnection.new(media_storage.get_adapter)
        @_external_album = media_connection.get_album_by_id(self.external_album)
      end
      
      puts "album #{self.external_album} external_album : #{@external_album.to_json}"
      
      @_external_album
      
    end
                
  end #Album
end #Media