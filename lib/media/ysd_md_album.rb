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
    property :name, String, :length => 100
    property :root, Boolean, :default => true # Identifies if it's a root album or an album bounded to other entity
    property :album_context, String, :length => 100 # Identifies the entity the album is bounded to
    property :description, String, :length => 255
    property :width, Integer
    property :height, Integer


    has n, :photos, 'Media::Photo', :constraint => :destroy 

    property :adapter_name, String, length: 50

    has 1, :album_cover
        
    #
    # Saves the album
    #
    def save
      
      if self.new?
        unless adapter_name
          adapter_name = SystemConfiguration::Variable.get_value('media.adapter','filesystem') 
        end  
      end
    
      begin 
        super
        if name.nil? and album_context
          update(:name => album_context)
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
    # @return [Media::Photo]
    #   The photo with the updated information
    #
    def add_or_update_photo(photo_data, photo_file, filename)

      if photo_data.has_key?(:photo_id)
        photo = Media::Photo.get(photo_data[:photo_id])
      else  
        photo = Media::Photo.create({:album => self, 
             :name => photo_data[:photo_name],
             :description => photo_data[:photo_description]})
      end

      photo.store_photo(photo_file, filename)

      return photo
    
    end

    #
    # Get the album cover photo URL
    #
    def image_url
      album_cover ? album_cover.photo.photo_url_full : photos.size > 0 ? photos.first.photo_url_full : nil
    end

    #
    # Get the album cover photo
    #
    def image_cover
      album_cover ? album_cover.photo : photos.size > 0 ? photos.first : nil
    end

    #
    # Get the image path
    #
    def image_path
      photo = album_cover ? album_cover.photo : photos.first
      
      return "/album/#{id}/photo/#{photo.id}"
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

    def get_adapter
      # It creates an adapter any time for multi-tenant solution
      Adapters::Factory.instance.create_adapter(SystemConfiguration::Variable.get_value('media.adapter','filesystem'))
    end  
                
  end #Album
end #Media