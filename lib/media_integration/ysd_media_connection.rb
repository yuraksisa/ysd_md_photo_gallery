module MediaIntegration

  #
  # Represents the connection to a media repository (picasa, flickr, ...)
  #
  # The connection is made through an adapter
  #
  # Usage: 
  #
  #   adapter = MediaIntegration::Adapters::PicasaAdapter('my-account', 'my-password')
  #   media_connection = MediaIntegration::MediaConnection.new(adapter)
  #   media_connection.get_albums # Retrieve all albums  
  #
  #   album = MediaIntegration::Album.new(my_adapter)
  #   album.save
  #
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
    #   array of MediaIntegration::Album
    #
    def get_albums
    
      if @albums_loaded
        albums = AlbumCache.instance.all(@adapter)
      else     
        albums = @adapter.get_albums
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

end