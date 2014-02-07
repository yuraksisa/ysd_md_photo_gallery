module MediaIntegration
  #
  # Cache for storing albums organized by adapter
  #
  # - albums : {adapter, [Array of albums]}
  # 
  #
  class AlbumCache
    include Singleton
  
    def initialize
      @albums = {}
      @albums_name_hash = {}
      @albums_id_hash = {}
    end
    
    #
    # Store an album in the cache
    #
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
    
    #
    # Get an album from the cache by its id
    #
    def get_by_id(adapter, album_id)
      if @albums_id_hash.has_key?(adapter)
        @albums_id_hash[adapter][album_id]
      else
        return nil
      end
    end
    
    #
    # Get an album from the cache by its name
    #
    def get_by_name(adapter, album_name)
      if @albums_name_hash.has_key?(adapter)
        @albums_name_hash[adapter][album_id]
      else
        return nil
      end
    end

    #
    # Retrieve all albums from the cache
    #    
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

end
