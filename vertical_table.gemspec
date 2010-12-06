Gem::Specification.new do |s|
  s.name = "vertical_table"
  s.version = "0.1.3"
  s.date    = "2010-12-06"
  
  s.description = "Uses an association to provide 'virtual' attributes on a model through the use of a veritcal table. Great for 'Preferences' type situations."
  s.summary = "Quick and easy way persistant virtual attributes."
  
  s.authors = ["Alexander Bartlow"]
  s.email = "bartlowa@gmail.com"
  
  s.require_paths = ["lib"]
  s.executables = []
  
  s.add_development_dependency 'test/unit'
  s.add_development_dependency 'rails', '~>2.3'
  s.add_development_dependency 'active_support', '~>2.3'
  s.add_development_dependency 'active_record', '~>2.3'
  s.add_development_dependency 'shoulda'
  
  s.files = `git ls-files`.split("\n")
end