module MediaIntegration
  #
  # Represents a Photo thumbnail
  #
  class PhotoThumbnail
    include MediaIntegration::ToJSON
  
    attr_accessor :thumbnail_url, :width, :height
  
    def initialize(url, the_width, the_height)
      @thumbnail_url = url
      @width = the_width
      @height = the_height
    end
    
  end
end