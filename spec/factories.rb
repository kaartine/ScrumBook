Factory.define :user do |f|  
  f.username "foo"  
  f.password_clear "admin"
  f.salt "1234"
  f.admin false
#  f.password_confirmation { |u| u.password }  
end
