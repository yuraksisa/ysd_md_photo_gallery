require 'gdata'
# 
# Using it:
# 
#  adapter = PhotoCollection::PicasaAdapter.new('username','password', true)
#  album = PhotoCollection::Album.new
#  album.name = 'name'
#  adapter.create_album(album)
#
#
# References:
#
#  API Google
#  ----------
#  http://code.google.com/intl/es-ES/apis/picasaweb/docs/2.0/developers_guide_protocol.html
#
#  GDATA
#  ----------
#  http://code.google.com/p/gdata-ruby-util/
#
module PhotoCollection

  class PicasaAdapter

    #
    # Constructor
    #
    def initialize(user_account, user_password)
       @user = user_account
       @password = user_password
    end

    def with_client 
    
      begin
        picasa_client = GData::Client::Photos.new
        picasa_client.clientlogin @user + '@gmail.com' , @password
        yield picasa_client
      ensure
        # There is not logout in the library     
      end 
    
    end

    # --------------- Querying ---------------
    
    #
    # Get all user's albums
    #
    def get_albums
      
      feed=nil
      
      with_client do |client|
      
        feed = client.get("http://picasaweb.google.com/data/feed/api/user/#{@user}").to_xml #REXML::Document

      end
      
      albums = []
      feed.elements.each('entry') do |entry|
        album = PhotoCollection::Album.new(self)
        entry_to_album(entry, album)
        albums << album
      end

      albums
      
    end

    #
    # Get all album's photo
    #
    def get_photos(user_id, album_id)
    
      feed=nil
      with_client do |client|
        feed = client.get("http://picasaweb.google.com/data/feed/api/user/#{user_id}/albumid/#{album_id}").to_xml
      end
      
      photos = []
      
      feed.elements.each('entry') do |entry|
         photo = PhotoCollection::Photo.new(self)
         entry_to_photo(entry, photo)         
         photos << photo
      end
      
      return photos
    
    end    
    
    #
    # Gets a photo
    #
    def get_photo(user_id, album_id, photo_id)
    
      feed=nil
      with_client do |client|
        feed = client.get("http://picasaweb.google.com/data/feed/api/user/#{user_id}/albumid/#{album_id}/photoid/#{photo_id}").to_xml
      end
      
      photo = PhotoCollection::Photo.new(self)
      
      feed.elements('entry') do |entry|
        entry_to_photo(entry, photo)
        break
      end
      
      return photo
    
    end    


    # --------------- CRUD Albums ------------

    #
    # Creates an album
    #
    def create_album(album)
  
      album_str = album_to_entry(album)
      entry = nil
           
      with_client do |client|
        entry = client.post("https://picasaweb.google.com/data/feed/api/user/#{@user}", album_str).to_xml
      end
      
      entry_to_album(entry, album) # Updates the album data
      
      puts "Album created #{album.name} #{album.user} "
      
    end

    #
    # Updates the album information
    #
    def update_album(album)
    
      album_str = album_to_entry(album)
      
      entry = nil
      
      with_client do |client|
        #client.headers['Content-Type'] = 'application/atom+xml'
        client.headers['If-Match'] = '*'
        entry = client.put("https://picasaweb.google.com/data/entry/api/user/#{album.user}/albumid/#{album.id}", album_str).to_xml
      end
      
      entry_to_album(entry, album) # Updates the album data
    
      puts "Album updated #{album}"
    
    end
    
    #
    # Deletes an album
    # 
    def delete_album(album)
    
      with_client do |client|
        client.headers['Content-Type'] = 'application/atom+xml'
        client.headers['If-Match'] = '*'
        client.delete("https://picasaweb.google.com/data/entry/api/user/#{album.user}/albumid/#{album.id}")
      end
      
    end

    #
    # ------------- CRUD Photos --------------
    #
    
    #
    # Create a photo with metadata
    #
    def create_photo(photo)
   
      puts "photo : #{photo_to_entry(photo)}"
      mime_type = photo.mime_type || 'image/jpeg'
      body = GData::HTTP::MimeBody.new(photo_to_entry(photo), photo.file, mime_type)
      entry = nil    
      with_client do |client|
        client.headers['Content-Type'] = body.content_type # Necesario pq sino da un error en el POST
        entry = client.post("https://picasaweb.google.com/data/feed/api/user/#{photo.album.user}/albumid/#{photo.album.id}", body).to_xml
      end
      
      entry_to_photo(entry, photo) #Update the photo data
      
      puts "Photo created #{photo}"
    
    end
    
    #
    # Post a photo to an album not including metadata
    #
    # @param file Represents an open file
    #
    def create_photo_no_metadata(photo)
      
      mime_type = photo.mime_type || 'image/jpeg'
      
      entry = nil
      
      with_client do |client|
        client.headers['Content-Type'] = mime_type #Nota : Para utilizar post (sin metadata, necesitamos especificar el header Content-Type)
        entry = client.post("http://picasaweb.google.com/data/feed/api/user/#{photo.album.user}/albumid/#{photo.album.id}", photo.file).to_xml
      end
      
      entry_to_photo(entry, photo) #Update the photo data      
                                      
    end
    
    #
    # Update a photo : File + metadata
    #
    def update_photo(photo)
    
      puts "photo : #{photo_to_entry(photo)}"
      mime_type = photo.mime_type || 'image/jpeg'
      body = GData::HTTP::MimeBody.new(photo_to_entry(photo), photo.file, mime_type)  
      entry = nil
      with_client do |client|
        client.headers['If-Match'] = '*'
        client.headers['Content-Type'] = body.content_type
        entry = client.put("https://picasaweb.google.com/data/media/api/user/#{photo.album.user}/albumid/#{photo.album.id}/photoid/#{photo.id}", body).to_xml
      end
      
      entry_to_photo(entry, photo) #Update the photo data
      
      puts "Photo updated #{photo}"
    
    end
   
    # 
    # Update a photo : Only its metadata
    #
    def update_photo_only_metadata(photo)
   
      entry = nil
      with_client do |client|
        client.headers['Content-Type'] = 'application/atom+xml'
        client.headers['If-Match'] = '*'
        entry = client.put("https://picasaweb.google.com/data/entry/api/user/#{photo.album.user}/albumid/#{photo.album.id}/photoid/#{photo.id}", photo_to_entry(photo)).to_xml 
      end
      
      entry_to_photo(entry, photo)
   
    end
    
    #
    # Update a photo : Only the file
    #
    def update_photo_no_metadata(photo)
      
      mime_type = photo.mime_type || 'image/jpeg'
      entry = nil
      with_client do |client|
        client.headers['Content-Type'] = mime_type #Nota : Para utilizar post (sin metadata, necesitamos especificar el header Content-Type)
        client.headers['If-Match'] = '*'
        entry = client.put("http://picasaweb.google.com/data/media/api/user/#{photo.album.user}/albumid/#{photo.album.id}/photoid/#{photo.id}/#{photo.version}", file).to_xml
      end
      
      entry_to_photo(entry, photo)  

    end    
   
    #
    # Delete a photo 
    #
    def delete_photo(photo)
    
      with_client do |client|
        client.headers['Content-Type'] = 'application/atom+xml'
        client.headers['If-Match'] = '*'
        client.delete("https://picasaweb.google.com/data/entry/api/user/#{photo.album.user}/albumid/#{photo.album.id}/photoid/#{photo.id}")    
      end
      
    end
    
    # ------------- Extras ------------
    
    #
    # Get the image
    #
    def image_url_to_size(image_url, width, height)
      
      path = image_url
      size = [width, height].max
      
      if path_parts=image_url.match(/(.+)\/(.+)$/)
        path = "#{path_parts[1]}/s#{size}/#{path_parts[2]}"
      end
      
      return path
      
    end
    
    private
    
    #
    # Updates the album data from an entry
    #
    def entry_to_album(entry, album)
      album.id = entry.elements['gphoto:id'].text
      album.user = entry.elements['gphoto:user'].text
      album.name = entry.elements['title'].text
      album.summary = entry.elements['summary'].text
      album.size = entry.elements['gphoto:numphotos'].text.to_i
      album.remaining = entry.elements['gphoto:numphotosremaining'].text.to_i
      album.bytes_used = entry.elements['gphoto:bytesUsed'].text.to_i
      album.image_url = entry.elements['media:group'].elements['media:content'].attributes['url']
      album.thumbnail_url = entry.elements['media:group'].elements['media:thumbnail'].attributes['url']
    
    end
    
    #
    # Creates the text that represents the album
    #
    def album_to_entry(album)
    
      entry = "<entry xmlns='http://www.w3.org/2005/Atom' xmlns:media='http://search.yahoo.com/mrss/' xmlns:gphoto='http://schemas.google.com/photos/2007'>"
      entry << "<title type='text'>#{album.name}</title>"
      entry << "<summary type='text'>#{album.summary}</summary>"
      entry << "<gphoto:id>#{album.id}</gphoto:id>" if album.id
      #entry << "<gphoto:location></gphoto:location>"
      #entry << "<gphoto:timestamp></gphoto:timestamp>"
      #entry << "<media:group>"
      #entry << "  <media::keywords></media::keywords>"
      #entry << "</media::group>"
      entry << "<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#album'></category>"
      entry << "</entry>"
      
    end
    
    #
    # Updates the photo data from an entry
    #
    def entry_to_photo(entry, photo)
      photo.id = entry.elements['gphoto:id'].text
      photo.version = entry.elements['gphoto:version'].text
      photo.width = entry.elements['gphoto:width'].text.to_i
      photo.height = entry.elements['gphoto:height'].text.to_i
      photo.image_url = entry.elements['media:group'].elements['media:content'].attributes['url']
      photo.name = entry.elements['media:group'].elements['media:title'].text
      photo.description = entry.elements['media:group'].elements['media:description'].text
         
      photo.thumbnails = []
      # Load the thumbnails
      entry.elements['media:group'].elements.each('media:thumbnail') do |thumbnail|
        pt = PhotoCollection::PhotoThumbnail.new(thumbnail.attributes['url'], thumbnail.attributes['width'], thumbnail.attributes['height'])
        photo.thumbnails << pt
      end    
    
      return photo
      
    end
    
    #
    # Creates the text that represents the photo
    #
    def photo_to_entry(photo)

      entry = "<entry xmlns='http://www.w3.org/2005/Atom' xmlns:media='http://search.yahoo.com/mrss/' xmlns:gphoto='http://schemas.google.com/photos/2007'>"
      entry << "<title type='text'>#{photo.name}</title>" ##{File.basename(photo.file.path)}
      entry << "<summary type='text'>#{photo.name}</summary>"
      entry << "<gphoto:id>#{photo.id}</gphoto:id>" if photo.id
      entry << "<gphoto:version>#{photo.version}</gphoto:version>" if photo.version
      #entry << "<gphoto:location></gphoto:location>"
      #entry << "<gphoto:timestamp></gphoto:timestamp>"
      entry << "<media:group>"
      entry << "<media:title type='plain'>#{photo.name}</media:title>"
      entry << "<media:description type='plain'>#{photo.description}</media:description>"
      entry << "</media:group>"
      entry << "<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/photos/2007#photo'></category>"
      entry << "</entry>"

    end

  end

end