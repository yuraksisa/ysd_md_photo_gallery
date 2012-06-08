Gem::Specification.new do |s|
  s.name    = "ysd_md_photo_gallery"
  s.version = "0.1"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2011-09-15"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb']
  s.description = "Photo Collection management"
  s.summary = "Configuration for webapps"
  
  s.add_runtime_dependency "data_mapper", "1.1.0"  
  s.add_runtime_dependency "gdata_19"              # Picasa API
  
  s.add_runtime_dependency "ysd_md_integration"    # The account associated to an album
  
end
