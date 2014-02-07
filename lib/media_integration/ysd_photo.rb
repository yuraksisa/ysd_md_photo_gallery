module MediaIntegration
  #
  # Represents a photo
  #
  class Photo
    include MediaIntegration::ToJSON
    attr_accessor :id, :name, :description, :version, :width, :height, :image_url, :thumbnails, :album, :file, :mime_type
  
    #
    # Constructor
    #
    def initialize(adapter)
      @adapter = adapter
    end
    
  
    # ------------ Instance methods -----------------

    def to_json(*a)
    
      { :id => id,
        :name => name,
        :description => description,
        :version => version,
        :width => width,
        :height => height,
        :image_url => image_url,
        :thumbnails => thumbnails,
        :album => {:id => album.id, :name => album.name},
        :mime_type => mime_type
      }.to_json
     
    end
    
    #
    # Get the image
    #
    def get_image_url(width, height)
      
      @adapter.image_url_to_size(image_url, width, height)
      
    end
  
    #
    # Stores the photo
    #
    def save(only_photo=false)
        
      if self.id # Update an existing photo
      
        if self.file
          @adapter.update_photo(self)
        else
          @adapter.update_photo_only_metadata(self) 
        end

        # Update the photo album in memory because we have updated the photo directly
        if only_photo
          self.album.change_photo(self)
        end
         
      else # Create a new photo
      
        @adapter.create_photo(self)
        
        # Update the photo album in memory because we have updated the photo directly       
        if only_photo
          self.album.photos << self
        end
      end 
    
    end
    
    #
    # Deletes the photo
    #
    def delete
    
      if self.id
        @adapter.delete_photo(self)
      end
    
    end
    
  end
end  