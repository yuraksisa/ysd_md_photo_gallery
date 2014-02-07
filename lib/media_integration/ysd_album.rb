module MediaIntegration
  #
  # Represents an album
  #
  class Album
    include MediaIntegration::ToJSON
  
    attr_accessor :id, :version, :name, :user, :summary, :size, :remaining, :bytes_used, :image_url, :thumbnail_url
    attr_reader :adapter
    
    def initialize(adapter)
      @adapter = adapter
    end
           
    #
    # Get all the album's photos
    #    
    def photos
    
      if @photos
        return @photos
      else
        @photos = self.id ? get_photos : []
      end
    
    end    
          
    #
    # Stores the album information
    #
    def save
     
      if self.id  # It's an existing album 
        @adapter.update_album(self)
      else        # It's a new album
        @adapter.create_album(self)
        AlbumCache.instance.store(@adapter, self)
      end
            
      self.photos.each do |photo| 
        photo.save 
      end
      
    end
   
    #
    # Delete the album
    #
    def delete
      if self.id
        @adapter.delete_album(self)
      end
      
      # TODO Remove from the @@albums      
    end
    
    #
    # Change a photo in the list of photos
    #
    def change_photo(photo)
       index = nil
       photos.each_index do |i| # From Ruby 1.8.7 it can be done with index
         if photos[i].id == photo.id
           index = i
           break
         end
       end
       photos[index] = photo if index   
    end
       
    private
    
    # Retrieve the album's photos
    # private @api
    #
    def get_photos
 
      the_photos = @adapter.get_photos(user, id)
      
      the_photos.each do |photo| 
        photo.album=self 
      end
 
      return the_photos
          
    end
                    
  end
end  