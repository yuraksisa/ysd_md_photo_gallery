Gem::Specification.new do |s|
  s.name    = "ysd_md_photo_gallery"
  s.version = "0.2.0"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2011-09-15"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb']
  s.description = "Media albums management"
  s.summary = "Media albums management"
  s.homepage = "http://github.com/yuraksisa/ysd_md_attachment"  
  
  s.add_runtime_dependency "data_mapper", "1.2.0"  # DataMapper
  s.add_runtime_dependency "gdata_19"              # Picasa API
  s.add_runtime_dependency "json"                  # JSON
    
  s.add_runtime_dependency "ysd_md_integration"    # The account associated to an album
  s.add_runtime_dependency "ysd_md_configuration"  # To access to the system configuration
  s.add_runtime_dependency "ysd_core_plugins"     # Aspects
  
end
