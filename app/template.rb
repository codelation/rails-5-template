copy_file 'app/controllers/application_controller.rb', force: true
copy_file 'app/controllers/pages_controller.rb'
copy_file 'app/views/layouts/application.html.erb', force: true
copy_file 'app/views/pages/index.html.erb'
copy_file "app/views/layouts/shared/_header.html.erb"
copy_file "app/views/layouts/shared/_footer.html.erb"
copy_file "app/views/layouts/shared/_flash_messages.html.erb"

copy_file "app/assets/stylesheets/application.scss"

copy_file "app/javascript/packs/application.js"
copy_file "app/javascript/support/application-controller.js"

copy_file "app/services/callable.rb"
