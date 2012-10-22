require 'data_mapper' unless defined?DataMapper
require 'ysd_md_externalserviceaccount' unless defined?(Integration::ExternalServiceAccount)
require 'ysd_md_configuration' unless defined?(SystemConfiguration::Variable)

module Media
  
  #
  # It represents an Album
  #
  class Album
    include DataMapper::Resource
    
    property :name, String, :field => 'name', :length => 40, :key => true
    property :description, String, :field => 'description', :length => 255
        
    property :width, Integer, :field => 'width'    # The element width
    property :height, Integer, :field => 'height'  # The element height
    
    property :external_album, String, :field => 'external_album', :length => 50 # The external album 
    property :adapter, String, :field => 'adapter', :length => 12
    belongs_to :account, 'ExternalIntegration::ExternalServiceAccount', :child_key => ['account_id'], :parent_key => ['id'], :required => false

    property :size, Integer, :field => 'size' # Number of items which are hold
    property :remaining, Integer, :field => 'remaining' # Remaining number of items
    property :bytes_used, Integer, :field => 'bytes_used' # The total space used
    property :image_url, String, :field => 'image_url', :length => 128
    property :thumbnail_url, String, :field => 'thumbnail_url', :length => 128
    
    alias old_save save
    
    #
    # Before creating the album
    #
    before :create do |album|
    
      unless adapter
        album.adapter = SystemConfiguration::Variable.get_value('photo_default_adapter')
      end
      
      unless account 
        if default_account = SystemConfiguration::Variable.get_value('photo_default_account')
          album.account = ExternalIntegration::ExternalServiceAccount.get(default_account)
        end
      end
    
    end
        
    #
    # Saves the album
    #
    def save
        
      if self.account and (not self.account.saved?)
        self.account = ExternalIntegration::ExternalServiceAccount.get(self.account.id)
      end
     
      old_save
    
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
    # @return [PhotoCollection::Photo]
    #   The photo with the updated information
    #
    def add_or_update_photo(photo_data, photo_file)
    
      # Adjusts the image          
      img_file = photo_file
      
      if img=adjust_image(photo_file,{:width => self.width, :height => self.height})
        img_file = StringIO.new(img.to_blob)
      end
            
      #  the photo
      photo = PhotoCollection::Photo.new(get_adapter)           
      photo.id = photo_data[:photo_id]
      photo.name = photo_data[:photo_name] 
      photo.description = photo_data[:photo_description] 
      photo.file = img_file
                 
      # Load the album                  
      destination_album = get_external_album
      
      unless destination_album
        destination_album = PhotoCollection::Album.new(get_adapter)
        destination_album.name = name       
        photo.album = destination_album
        destination_album.photos << photo
        destination_album.save
        
        self.external_album = destination_album.id
        self.save

      else
        photo.album = destination_album
        photo.save(true)
      end
    
      return photo
    
    end

    #
    # Removes a photo from the album
    #
    def delete_photo(photo_id)
    
      if photo = (photos.select { |photo| photo.id == photo_id }).first
        photo.delete
      end
      
    end

    #
    # Gets the albums photos
    #
    # @return [Array]
    #   An array of PhotoCollection::Photo
    #
    def photos
      adapted_album.photos
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
    
    private
                
    #
    # Gets the adapter (to access the external album)
    #
    def get_adapter
      unless defined?(@_adapter)
        puts "creating adapter #{account.username} #{adapter}"
        @_adapter = PhotoCollection::PicasaAdapter.new(account.username, account.password) if self.adapter == 'picasa' and account
        puts "created adapter #{account.username} #{adapter}"
      end
      @_adapter
    end
            
    #
    # Gets the external album (used to manage the photos)
    #
    def get_external_album
     
      unless defined?(@_external_album)
        media_connection = PhotoCollection::MediaConnection.new(get_adapter)
        @_external_album = media_connection.get_album_by_id(self.external_album)
      end
      
      puts "album #{self.external_album} external_album : #{@external_album.to_json}"
      
      @_external_album
      
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
         img.resize_to_fill(options[:width], options[:height], Magick::CenterGravity)
       end
    
    end 
        
  end #Album
end #Media