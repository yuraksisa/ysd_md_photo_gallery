require 'singleton'

# Using the library
# -----------------
# 
# my_adapter = PhotoCollection::PicasaAdapter('my-account', 'my-password')
# media_connection = PhotoCollection::MediaConnection.new(my_adapter)
# 
# RETRIEVING ALBUMS
#
# media_connection.get_albums # Retrieve all albums
#
# CREATING A NEW ALBUM
#
# album = PhotoCollection::Album.new(my_adapter)
# album.save
#
module PhotoCollection

  class AlbumCache
    include Singleton
  
    def initialize
      @albums = {}
      @albums_name_hash = {}
      @albums_id_hash = {}
    end
    
    def store(adapter, album)
    
      unless @albums_id_hash.has_key?(adapter)
       
        @albums.store(adapter, [])
        @albums_name_hash.store(adapter, {})
        @albums_id_hash.store(adapter, {})
      
      end
      
      unless @albums_id_hash[adapter].has_key?(album.id)
        
        @albums[adapter] << album
        @albums_name_hash[adapter].store(album.name, album)
        @albums_id_hash[adapter].store(album.id, album)
      
      end
    
    end
    
    def get_by_id(adapter, album_id)
    
      if @albums_id_hash.has_key?(adapter)
        @albums_id_hash[adapter][album_id]
      else
        return nil
      end
      
    end
    
    def get_by_name(adapter, album_name)
     
      if @albums_name_hash.has_key?(adapter)
        @albums_name_hash[adapter][album_id]
      else
        return nil
      end
      
    end
    
    def all(adapter)
      @albums[adapter]
    end
  
    def inspect
     
      result = ""
      
      @albums.each do |adapter, albums_list|       
       albums_list.each do |album|
         result << "adapter : #{adapter.class.name} - album : #{album.id} #{album.name}\n"
       end
      end
    
      result
    
    end
  
  end

  # 
  # It represents a connection to a media repository
  #
  class MediaConnection
      
    attr_reader :adapter
    
    def initialize(adapter)
      @adapter = adapter
      @albums_loaded = false
    end
  
    # Retrieve all albums
    #
    # @return [Array]
    #   array of PhotoCollection::Album
    #
    def get_albums
    
      if @albums_loaded
        albums = AlbumCache.instance.all(@adapter)
      else     
        albums = @adapter.get_albums
        puts "albums : #{albums.to_json}"
        albums.each do |album|
          AlbumCache.instance.store(@adapter, album)
        end
        @albums_loaded = true            
      end
           
      return albums
     
    end  
    
    #
    # Retrieve an album by its name
    #
    def get_album_by_name(album_name)

      if not @albums_loaded
        self.get_albums
      end
      
      AlbumCache.instance.get_by_name(@adapter, album_name)      
        
    end
    
    #
    # Retrieve an album by its id
    #
    def get_album_by_id(album_id)

      if not @albums_loaded
        self.get_albums
      end
      
      AlbumCache.instance.get_by_id(@adapter, album_id)      
    
    end
    
  end

  #
  # Represents an album
  #
  class Album
    include PhotoCollection::ToJSON
  
    attr_accessor :id, :version, :name, :user, :summary, :size, :remaining, :bytes_used, :image_url, :thumbnail_url
    
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
  
  #
  # Represents a photo
  #
  class Photo
  
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
  
  #
  # Represents a Photo thumbnail
  #
  class PhotoThumbnail
    include PhotoCollection::ToJSON
  
    attr_accessor :thumbnail_url, :width, :height
  
    def initialize(url, the_width, the_height)
      @thumbnail_url = url
      @width = the_width
      @height = the_height
    end
    
  end
  
  
end