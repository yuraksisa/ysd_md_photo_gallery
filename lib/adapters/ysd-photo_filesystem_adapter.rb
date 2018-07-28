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
  class FileSystemAdapter < BaseAdapter

    attr_reader :root_folder, :container_folder, :server_name_folder

    #
    # Constructor
    #
    def initialize(root_folder)
      @root_folder = root_folder
      if snf = BaseAdapter.server_name_folder
        @server_name_folder = snf
        @container_folder = File.join(@root_folder, @server_name_folder)
      else
        @server_name_folder = nil
        @container_folder = @root_folder
      end
    end	

    #
    # Creates an album
    #      
    def create_album(album_id)
      FileUtils.mkdir_p(File.join(@container_folder, album_id.to_s))
    end      	

    #
    # Deletes an album
    #
    def delete_album(album_id)
    	raise "invalid folder" if @container_folder.nil? || @container_folder.empty? || ['/','/usr','/bin','/opt'].include?(@container_folder)
      FileUtils.rm_rf(File.join(@container_folder, album_id.to_s), {secure: true})
    end

    #
    # Create a photo with metadata
    #
    def create_photo(album_id, photo_id, file, filename)

      # Make folder
      FileUtils.mkdir_p(File.join(@container_folder, album_id.to_s, photo_id.to_s))
      
      # Copy file
      FileUtils.copy(file, File.join(@container_folder, album_id.to_s, photo_id.to_s, filename))

      # Create thumbnails
      create_thumbnails(album_id, photo_id, file, filename)

    end

    #
    # Create a photo with metadata
    #
    def update_photo(album_id, photo_id, file, filename)
        
      # Delete the old photo files
      delete_photo(album_id, photo_id)

      # Creates the folder if not exist
      FileUtils.mkdir_p(File.join(@container_folder, album_id.to_s, photo_id.to_s))
      # Creates the photo
      FileUtils.copy(file, File.join(@container_folder, album_id.to_s, photo_id.to_s, filename))
      # Create thumbnails
      create_thumbnails(album_id, photo_id, file, filename)

    end

    # Delete a photo 
    #
    def delete_photo(album_id, photo_id)
    	raise "invalid folder" if @container_folder.nil? || @container_folder.empty? || ['/','/usr','/bin','/opt'].include?(@container_folder)
      FileUtils.rm_rf(File.join(@container_folder, album_id.to_s, photo_id.to_s), {secure: true})
    end

    private 

    #
    # Create thumbnails
    #
    def create_thumbnails(album_id, photo_id, file, filename)
        
      img = Magick::Image.read(file.path).first
        
      medium = img.resize_to_fit(::Media::MEDIUM_SIZE)
      FileUtils.mkdir_p(File.join(@container_folder, album_id.to_s, photo_id.to_s, 'medium'))
      medium.write(File.join(@container_folder, album_id.to_s, photo_id.to_s, 'medium', filename))
        
      small = img.resize_to_fit(::Media::SMALL_SIZE)
      FileUtils.mkdir_p(File.join(@container_folder, album_id.to_s, photo_id.to_s, 'small'))
      small.write(File.join(@container_folder, album_id.to_s, photo_id.to_s, 'small', filename))
        
      tiny = img.resize_to_fit(::Media::TINY_SIZE)
      FileUtils.mkdir_p(File.join(@container_folder, album_id.to_s, photo_id.to_s, 'tiny'))
      tiny.write(File.join(@container_folder, album_id.to_s, photo_id.to_s, 'tiny', filename))

      # Build result
      if @server_name_folder
        result = {image_url: File.join('/uploads', @server_name_folder, album_id.to_s, photo_id.to_s, filename),
                  image_url_medium: File.join('/uploads', @server_name_folder, album_id.to_s, photo_id.to_s, 'medium', filename),
                  image_url_small: File.join('/uploads', @server_name_folder, album_id.to_s, photo_id.to_s, 'small', filename),
                  image_url_tiny: File.join('/uploads', @server_name_folder, album_id.to_s, photo_id.to_s, 'tiny', filename)}
      else
        result = {image_url: File.join('/uploads', album_id.to_s, photo_id.to_s, filename),
                  image_url_medium: File.join('/uploads', album_id.to_s, photo_id.to_s, 'medium', filename),
                  image_url_small: File.join('/uploads', album_id.to_s, photo_id.to_s, 'small', filename),
                  image_url_tiny: File.join('/uploads', album_id.to_s, photo_id.to_s, 'tiny', filename)}
      end

    end

  end  

end  	