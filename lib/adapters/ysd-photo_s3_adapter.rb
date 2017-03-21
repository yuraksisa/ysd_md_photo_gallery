# 
# Using it:
# 
#  adapter = MediaIntegration::Adapters::PicasaAdapter.new('username',)
#  album = MediaIntegration::Album.new
#  album.name = 'name'
#  adapter.create_album(album)
#
module Adapters

  #
  # FileSystem adapter for media integration
  #
  class S3Adapter

    attr_reader :api_key, :secret_key, :bucket

    #
    # Constructor
    #
    def initialize(api_key, secret_ket, bucket)

      @api_key = api_key
      @secret_key = secret_key
      @bucket = bucket
  
    end	

    #
    # Creates an album
    #      
    def create_album(album_id)

    end       

    #
    # Deletes an album
    #
    def delete_album(album_id)

    end

    #
    # Create a photo with metadata
    #
    def create_photo(album_id, photo_id, file, filename)
        
    end

    #
    # Create a photo with metadata
    #
    def update_photo(album_id, photo_id, file, filename)
        
    end

    # Delete a photo 
    #
    def delete_photo(album_id, photo_id)

    end


  end                        

end  	