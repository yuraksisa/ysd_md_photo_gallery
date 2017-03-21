require 'fileutils'
require 'RMagick' unless defined?Magick

# 
# Using it:
# 
#  adapter = MediaIntegration::Adapters::PicasaAdapter.new('username',)
#  adapter.create_album(id)
#
module Adapters

  #
  # FileSystem adapter for media integration
  #
  class FileSystemAdapter

    attr_reader :root_folder

    #
    # Constructor
    #
    def initialize(root_folder)
      @root_folder = root_folder
    end	

    #
    # Creates an album
    #      
    def create_album(album_id)
      FileUtils.mkdir_p(File.join(@root_folder, album_id.to_s))
    end      	

    #
    # Deletes an album
    #
    def delete_album(album_id)
    	raise "invalid folder" if @root_folder.nil? || @root_folder.empty? || ['/','/usr','/bin','/opt'].include?(@root_folder)
      FileUtils.rm_rf(File.join(@root_folder, album_id.to_s), {secure: true})
    end

    #
    # Create a photo with metadata
    #
    def create_photo(album_id, photo_id, file, filename)
        
      # Make folder
      FileUtils.mkdir_p(File.join(@root_folder, album_id.to_s, photo_id.to_s))
      
      # Copy file
      FileUtils.copy(file, File.join(@root_folder, album_id.to_s, photo_id.to_s, filename))

      # Create thumbnails
      create_thumbnails(album_id, photo_id, file, filename)

    end

    #
    # Create a photo with metadata
    #
    def update_photo(album_id, photo_id, file, filename)
        
      # Delete the old photo files
      delete_photo(album_id, photo_id)
      # Creates the photo
      FileUtils.copy(file, File.join(@root_folder, album_id.to_s, photo_id.to_s, filename))
      # Create thumbnails
      create_thumbnails(album_id, photo_id, file, filename)

    end

    # Delete a photo 
    #
    def delete_photo(album_id, photo_id)
    	raise "invalid folder" if @root_folder.nil? || @root_folder.empty? || ['/','/usr','/bin','/opt'].include?(@root_folder)
      FileUtils.rm_rf(File.join(@root_folder, album_id.to_s, photo_id.to_s), {secure: true})       	
    end

    private 

    #
    # Create thumbnails
    #
    def create_thumbnails(album_id, photo_id, file, filename)
        
      img = Magick::Image.read(file.path).first
        
      medium = img.resize_to_fit(::Media::MEDIUM_SIZE)
      FileUtils.mkdir_p(File.join(@root_folder, album_id.to_s, photo_id.to_s, 'medium'))
      medium.write(File.join(@root_folder, album_id.to_s, photo_id.to_s, 'medium', filename))
        
      small = img.resize_to_fit(::Media::SMALL_SIZE)
      FileUtils.mkdir_p(File.join(@root_folder, album_id.to_s, photo_id.to_s, 'small'))
      small.write(File.join(@root_folder, album_id.to_s, photo_id.to_s, 'small', filename))
        
      tiny = img.resize_to_fit(::Media::TINY_SIZE)
      FileUtils.mkdir_p(File.join(@root_folder, album_id.to_s, photo_id.to_s, 'tiny'))
      tiny.write(File.join(@root_folder, album_id.to_s, photo_id.to_s, 'tiny', filename))

      # Build result
      result = {image_url: File.join('/uploads', album_id.to_s, photo_id.to_s, filename),
                image_url_medium: File.join('/uploads', album_id.to_s, photo_id.to_s, 'medium', filename),
                image_url_small: File.join('/uploads', album_id.to_s, photo_id.to_s, 'small', filename),
                image_url_tiny: File.join('/uploads', album_id.to_s, photo_id.to_s, 'tiny', filename)}

    end

  end  

end  	