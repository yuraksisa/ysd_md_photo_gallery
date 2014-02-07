module Media
  #
  # Album's cover
  #	
  class AlbumCover
    include DataMapper::Resource
    storage_names[:default] = 'media_album_covers'
    belongs_to :album, :key => true, :unique_index => :media_album_cover_album
    belongs_to :photo, :key => true
  end
end